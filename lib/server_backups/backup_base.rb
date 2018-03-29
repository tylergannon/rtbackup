# frozen_string_literal: true

require 'English'

module ServerBackups
    class BackupBase
        attr_reader :working_directory, :config, :logger, :s3, :backup_type

        BACKUP_TYPES = %i[incremental daily weekly monthly].freeze

        TIMESTAMP_FORMAT = '%Y-%m-%dT%H00.UTC%z'

        def initialize(config_file, working_directory, backup_type)
            @working_directory = working_directory
            @config = Config.new(config_file)
            Time.zone = config.time_zone
            @logger = config.logger
            @backup_type = backup_type.to_sym
            logger.debug "Initialized #{backup_type} #{self.class.name.demodulize.titleize}, " \
                         "prefix: '#{s3_prefix}'"
        end

        def incremental?
            backup_type == :incremental
        end

        class << self
            def daily(config_file, working_directory)
                new(config_file, working_directory, :daily)
            end

            def weekly(config_file, working_directory)
                new(config_file, working_directory, :weekly)
            end

            def monthly(config_file, working_directory)
                new(config_file, working_directory, :monthly)
            end

            def incremental(config_file, working_directory)
                new(config_file, working_directory, :incremental)
            end
        end

        def backup_filename
            "#{self.class.name.demodulize.underscore}.#{backup_type}.#{timestamp}.tgz"
        end

        def title
            self.class.name.demodulize.titleize
        end

        def take_backup
            logger.info "Creating #{backup_type} #{title} #{create_archive_command}"

            system create_archive_command
            unless last_command_succeeded?
                raise BackupCreationError.new("Received #{$CHILD_STATUS} from tar command.",
                                              self.class, backup_type)
            end
            logger.debug "Backup exited with #{$CHILD_STATUS}"
        end

        def s3_prefix
            File.join(config.prefix, self.class.name.demodulize.underscore,
                      backup_type.to_s, '/')
        end

        def backup_s3_key
            File.join(s3_prefix, File.basename(backup_filename))
        end

        def store_backup
            logger.info 'Upload file'
            @uploaded_file = s3.save backup_path, backup_s3_key
            logger.info 'Finished uploading file.'
        end

        def remove_old_backups
            s3.delete_files_not_newer_than s3_prefix, config.get_retention_threshold(backup_type)
        end

        def backup_path
            File.join(working_directory, backup_filename)
        end

        def do_backup
            load_resources
            take_backup
            store_backup
            # verify_backup
            remove_old_backups
        end

        def timestamp
            Time.zone.now.strftime(TIMESTAMP_FORMAT)
        end

        def load_resources
            # @mysql = Mys3ql::Mysql.new self.config
            @s3 = S3.new config
        end

        private

        def last_command_succeeded?
            $CHILD_STATUS.exitstatus.zero?
        end
    end
end
