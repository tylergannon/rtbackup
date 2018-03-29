# frozen_string_literal: true

module ServerBackups
    class MysqlIncrementalBackup < MysqlBackup
        def initialize(config_file, working_directory, database_name)
            database_name = 'mysql' if database_name == 'all'

            super(config_file, working_directory, :incremental, database_name)
        end

        class BinlogFilename
            attr_reader :path
            def initialize(path)
                @path = path
            end

            def log_index
                /(\d{6})/.match(File.basename(file)).captures.first
            end
        end

        def do_backup
            load_resources
            flush_logs
            each_bin_log do |file|
                index = BinlogFilename.new(file).index
                next if index.in?(already_stored_log_indexes)
                backup_single_bin_log(file)
            end
        end

        def s3_prefix
            File.join(config.prefix, 'mysql_backup', 'incremental', '/')
        end

        def flush_logs
            execute_sql('flush logs;')
        end

        def each_bin_log
            # execute 'flush logs'
            logs = Dir.glob("#{config.bin_log}.[0-9]*").sort_by { |f| f[/\d+/].to_i }
            logs_to_backup = logs[0..-2] # all logs except the last, which is in use
            logs_to_backup.each do |log_file|
                yield log_file
            end
        end

        # def each_remote_bin_log
        #     remote_bin_logs.each do |file|
        #         yield(**parse_remote_binlog_filename(file))
        #     end
        # end

        # def parse_remote_binlog_filename(file)
        #     filename = File.basename(file.key)
        #     prefix, index, timestamp = REMOTE_FILENAME_REGEX.match(filename).captures
        #     {
        #         key: file.key,
        #         file: file,
        #         prefix: prefix,
        #         index: index,
        #         timestamp: timestamp,
        #         datetime: Time.zone.strptime(timestamp, TIMESTAMP_FORMAT)
        #     }
        # end

        private

        REMOTE_FILENAME_REGEX = /(.*)\.(\d+)\.(.{15})/
        def already_stored_log_indexes
            remote_bin_logs.map do |s3object|
                _, index = REMOTE_FILENAME_REGEX.match(s3object.key).captures
                index
            end
        end

        def remote_bin_logs
            s3.bucket.objects(prefix: s3_prefix)
        end

        def backup_single_bin_log(file)
            logger.debug "Backing up #{file}."
            dest_filename = File.basename(file) + '.' + timestamp
            logger.info "Storing #{file} to #{dest_filename}"
            s3.save file, File.join(s3_prefix, dest_filename)
        end
    end
end
