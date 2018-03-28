# frozen_string_literal: true

module ServerBackups
    class MysqlIncrementalBackup < MysqlBackup
        def initialize(config_file, working_directory, database_name)
            database_name = 'mysql' if database_name == 'all'

            super(config_file, working_directory, :incremental, database_name)
        end

        def do_backup
            load_resources
            flush_logs
            stored_indexes = []
            each_remote_bin_log do |index:, **_x|
                stored_indexes << index
            end
            each_bin_log do |file|
                index = /(\d{6})/.match(File.basename(file)).captures.first
                if index.in?(stored_indexes)
                    logger.debug "Skipping #{file} because it's already stored."
                    next
                end
                dest_filename = File.basename(file) + '.' + timestamp
                logger.info "Storing #{file} to " + dest_filename
                s3.save file, File.join(s3_prefix, dest_filename)
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

        def each_remote_bin_log
            s3.bucket.objects(prefix: s3_prefix).each do |file|
                yield **parse_remote_binlog_filename(file)
            end
        end

        REMOTE_FILENAME_REGEX = /(.*)\.(\d+)\.(.{15})/
        def parse_remote_binlog_filename(file)
            filename = File.basename(file.key)
            prefix, index, timestamp = REMOTE_FILENAME_REGEX.match(filename).captures
            {
                key: file.key,
                file: file,
                prefix: prefix,
                index: index,
                timestamp: timestamp,
                datetime: Time.zone.strptime(timestamp, TIMESTAMP_FORMAT)
            }
        end
    end
end
