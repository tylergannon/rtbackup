# frozen_string_literal: true

require 'English'

module ServerBackups
    class WebsiteRestore
        attr_reader :config, :s3, :working_dir, :restore_point

        def initialize(config_file, working_dir, restore_point)
            @working_dir = working_dir
            @config = Config.new(config_file)
            @restore_point = restore_point
            Time.zone = config.time_zone
            @s3 = S3.new(config)
            logger.debug "Initialized #{self.class.name.demodulize.titleize}, " \
                         "prefix: '#{s3_prefix}'"
        end

        def files_to_restore
            [all_files.full_backup_for(restore_point),
             *all_files.incremental_backups_for(restore_point)]
        end

        def do_restore
            logger.warn "Moving old #{config.web_root} ---->>> #{config.web_root}.backup\n" \
                        'You will have to delete it yourself.'
            make_copy_of_existing_web_root
            files_to_restore.each_with_index { |file, index| restore_file(file, index) }
        end

        private

        def make_copy_of_existing_web_root
            FileUtils.mv config.web_root, "#{config.web_root}.backup" \
                if File.exist?(config.web_root)
            FileUtils.mkdir config.web_root
        end

        def restore_file(s3object, ordinal)
            local_filename = File.join(working_dir, "#{ordinal}.tgz")
            s3object.get response_target: local_filename
            system untar_command(local_filename)
            unless last_command_succeeded?
                raise BackupCreationError.new("Received #{$CHILD_STATUS} from tar command.",
                                              self.class, 'restore')
            end
            logger.info "Restored #{File.basename(s3object.key)}"
        end

        def untar_command(local_filename)
            <<-CMD
                tar zxp -C '/' --listed-incremental=/dev/null \
                --no-check-device \
                --file=#{local_filename}
            CMD
        end

        TIMESTAMP_REGEXP = /(\d{4})-(\d{2})-(\d{2})T(\d{2})00/
        def extract_backup_time_from_filename(filename)
            Time.zone.local(*TIMESTAMP_REGEXP.match(filename).captures)
        end

        def s3_prefix
            File.join(config.prefix, 'website_backup', '/')
        end

        def all_files
            @all_files ||= s3.get_ordered_collection(s3_prefix)
        end

        def logger
            config.logger
        end

        def last_command_succeeded?
            $CHILD_STATUS.exitstatus.zero?
        end
    end
end
