# frozen_string_literal: true

module ServerBackups
    class RestoreBase
        attr_reader :config, :s3, :working_dir, :restore_point, :database

        def initialize(config_file, working_dir, restore_point)
            @working_dir = working_dir
            @config = Config.new(config_file)
            @restore_point = restore_point
            Time.zone = config.time_zone
            @s3 = S3.new(config)
            logger.debug "Initialized #{title}."
        end

        private

        def title
            self.class.name.demodulize.titleize
        end

        TIMESTAMP_REGEXP = /(\d{4})-(\d{2})-(\d{2})T(\d{2})00\.UTC([+-]\d{4})/
        def extract_backup_time_from_filename(filename)
            time_parts = TIMESTAMP_REGEXP.match(filename).captures
            # Add in hours and seconds arguments
            # https://ruby-doc.org/core-2.2.0/Time.html#method-c-new
            time_parts.insert(4, 0, 0)
            Time.new(*time_parts)
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
