# frozen_string_literal: true

require 'tempfile'

module ServerBackups
    class MysqlRestore < RestoreBase
        ALL_DATABASES = 'all'

        def initialize(config_file, working_dir, restore_point, database)
            @database = database
            super config_file, working_dir, restore_point
        end

        def full_backup_file
            full_backup_prefix = File.join(config.prefix, 'mysql_backup', database)
            s3.get_ordered_collection(full_backup_prefix).full_backup_for(restore_point)
        end

        def incremental_backups
            incr_backup_prefix = File.join(config.prefix, 'mysql_backup')
            s3.get_ordered_collection(incr_backup_prefix).incremental_backups_for(restore_point)
        end

        def restore_script_path
            File.join(working_dir, "#{database}.sql")
        end

        ETC_TIMEZONE = '/etc/timezone'

        def formatted_restore_point_in_system_time_zone
            time_zone = File.exist?(ETC_TIMEZONE) ? File.read(ETC_TIMEZONE) : 'UTC'
            restore_point.in_time_zone(time_zone) \
                         .strftime('%Y-%m-%d %H:%M:%S')
        end

        def do_restore
            full_backup_file.get response_target: (restore_script_path + '.gz')
            system "gunzip #{restore_script_path}.gz"

            incremental_backups.each do |s3object|
                file = Tempfile.new('foo')
                begin
                    s3object.get response_target: file
                    file.close
                    system config.mysqlbinlog_bin + ' ' + file.path + \
                           " --stop-datetime='#{formatted_restore_point_in_system_time_zone}'" \
                           " --database=#{database} >> " + restore_script_path
                ensure
                    file.close
                    file.unlink # deletes the temp file
                end
            end

            execute_script restore_script_path
        end
        # #{@config.bin_path}mysqlbinlog --database=#{@config.database} #{file}
        class << self
            def restore(config_file, working_dir, restore_point, database)
                return new(config_file, working_dir, restore_point, database).do_restore \
                    if database != ALL_DATABASES

                all_databases(config_file, working_dir).each do |db_name|
                    new(config_file, working_dir, restore_point, db_name).do_restore
                end
            end

            def all_databases(config_file, working_dir)
                MysqlBackup.new(config_file, working_dir, 'daily', 'mysql').all_databases
            end
        end

        private

        def cli_options
            cmd = config.password.blank? ? '' : " -p'#{config.password}' "
            cmd + " -u'#{config.user}' " + database
        end

        def execute_script(path)
            cmd = "#{config.mysql_bin} --silent --skip-column-names #{cli_options}"
            logger.debug "Executing raw SQL against #{ database}\n#{cmd}"
            output = `#{cmd} < #{path}`
            logger.debug "Returned #{$CHILD_STATUS.inspect}. STDOUT was:\n#{output}"
            output.split("\n") unless output.blank?
        end
    end
end
