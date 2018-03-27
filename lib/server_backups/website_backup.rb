module ServerBackups
    class WebsiteBackup < BackupBase
        SNAPSHOT_PATH = Pathname('~/.var.www.backup.tar.snapshot.bin').expand_path
    
        attr_reader :uploaded_file, :backup_type

        def initialize(config_file, working_directory, backup_type)
            super(config_file, working_directory)
            @backup_type = backup_type
            logger.debug "Initialized #{backup_type} Website Backup, prefix: '#{s3_prefix}'"
        end

        private_class_method :new

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

        def backup_path
            File.join(self.working_directory, backup_filename)
        end

        def backup_filename
            "#{self.class.name.demodulize.underscore}.#{self.backup_type}.#{self.timestamp}.tgz"
        end
    
        def take_backup
            logger.info "Create #{backup_type} backup"
            logger.debug create_archive_command
            system create_archive_command
            if $?.exitstatus == 0
                logger.info "Done"
            else
                logger.error("Received #{$?.inspect} from tar command.")
                raise StandardError("Fooblaz")
            end
            unless File.exists?(backup_path)
                raise StandardError.new("Didn't create backup file.")
            end
            logger.debug "Backup exited with #{$?.inspect}"
        end
        
        def create_archive_command
            "tar --create --listed-incremental=#{SNAPSHOT_PATH} --gzip --no-check-device " +
            "--level=0 " +
            "--file=#{self.backup_path} #{config.web_root}"
        end

        class Incremental
            def create_archive_command
                "tar --create --listed-incremental=#{SNAPSHOT_PATH} --gzip --no-check-device " +
                "--file=#{self.backup_filename} -C #{config.web_root} #{config.web_root}"
            end
        end
    
        def s3_prefix
            File.join(self.config.prefix, 'www', self.backup_type.to_s, '/')
        end

        def backup_s3_key
            File.join(s3_prefix, File.basename(self.backup_filename))
        end
    
        def store_backup
            logger.info "Upload file"
            @uploaded_file = self.s3.save self.backup_filename, backup_s3_key
            logger.info "Finished uploading file."
        end
    
        def remove_old_backups
            s3.delete_files_not_newer_than s3_prefix, config.get_retention_threshold(backup_type)
        end
    end
end