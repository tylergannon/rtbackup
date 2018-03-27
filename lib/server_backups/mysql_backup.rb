module ServerBackups
    class MysqlBackup < BackupBase
        attr_reader :database_name

        SYSTEM_DATABASES = ['sys', 'information_schema', 'mysql', 'performance_schema'].freeze

        def initialize(config_file, working_directory, backup_type, database_name)
            @database_name = database_name
            super(config_file, working_directory, backup_type)
        end

        def do_backup
            if database_name == 'all'
                backup_all_databases
            else
                super
            end
        end

        def backup_all_databases
            @database_name = 'mysql'
            execute_sql("show databases;").reject { |db_name|
                db_name.in?(SYSTEM_DATABASES)
            }.each do |database|
                self.class.send(backup_type, 
                                config.config_file, 
                                working_directory, 
                                database).do_backup
            end
        end

        class << self
            def daily(config_file, working_directory, database_name)
                new(config_file, working_directory, :daily, database_name)
            end
            def weekly(config_file, working_directory, database_name)
                new(config_file, working_directory, :weekly, database_name)
            end
            def monthly(config_file, working_directory, database_name)
                new(config_file, working_directory, :monthly, database_name)
            end
            def incremental(config_file, working_directory, database_name)
                MysqlIncrementalBackup.new(config_file, working_directory, database_name)
            end
        end

        def create_archive_command
            cmd = config.mysqldump_bin + ' --quick --single-transaction --create-options '
            cmd += ' --flush-logs --master-data=2 --delete-master-logs ' if binary_logging?
            cmd + cli_options + ' | gzip > ' + backup_path
        end

        def s3_prefix
            File.join(self.config.prefix, self.class.name.demodulize.underscore, 
                      database_name, self.backup_type.to_s, '/')
        end

        def backup_filename
            "mysql_backup.#{self.backup_type}.#{self.timestamp}.sql.gz"
        end

        private

        def binary_logging?
            !config.bin_log.blank?
        end

        def cli_options
            cmd = config.password.blank? ? "" : " -p'#{config.password}' "
            cmd + " -u'#{config.user}' " + database_name
        end
      
        def execute_sql(sql)
            cmd = "#{config.mysql_bin} --silent --skip-column-names -e \"#{sql}\" #{cli_options}"
            logger.debug "Executing raw SQL against " + database_name
            logger.debug cmd
            output = `#{cmd}`
            logger.debug "Returned " + $?.inspect + ". STDOUT was:"
            logger.debug output
            unless output.blank?
                output.split("\n")
            end
        end
    end
end
