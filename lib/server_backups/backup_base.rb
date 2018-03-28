# frozen_string_literal: true

module ServerBackups
    class BackupBase
        attr_reader :working_directory, :config, :logger, :s3, :backup_type

        BACKUP_TYPES = %i[incremental daily weekly monthly].freeze

        TIMESTAMP_FORMAT = '%Y-%m-%dT%H00'

        def initialize(config_file, working_directory, backup_type)
            @working_directory = working_directory
            @config = Config.new(config_file)
            @logger = config.logger
            @backup_type = backup_type
            logger.debug "Initialized #{backup_type} #{self.class.name.demodulize.titleize}, prefix: '#{s3_prefix}'"
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

        def take_backup
            logger.info "Creating #{backup_type} #{self.class.name.demodulize.titleize}"
            logger.debug create_archive_command
            system create_archive_command
            if $CHILD_STATUS.exitstatus == 0
                logger.info 'Done'
            else
                logger.error("Received #{$CHILD_STATUS.inspect} from tar command.")
                raise BackupCreationError.new("Received #{$CHILD_STATUS.inspect} from tar command.",
                                              self.class, backup_type)
            end
            unless File.exist?(backup_path)
                raise BackupCreationError.new('tar exited successfully but file does not exist' \
                        ". \n\nCommand was: " + create_archive_command, self.class, backup_type)
            end
            logger.debug "Backup exited with #{$CHILD_STATUS.inspect}"
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
            Time.now.utc.strftime(TIMESTAMP_FORMAT)
        end

        def load_resources
            # @mysql = Mys3ql::Mysql.new self.config
            @s3 = S3.new config
        end
    end
end
