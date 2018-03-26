# lifted from https://github.com/airblade/mys3ql/blob/master/lib/mys3ql/config.rb

require 'yaml'
require 'logger'

module ServerBackups
    class Config

        attr_reader :logger, :logging

        DEFAULT_LOGFILE_SIZE = 1.megabytes
        DEFAULT_LOGFILE_COUNT = 7

        def initialize(config_file = nil)
            config_file = config_file || default_config_file
            @config = YAML.load_file File.expand_path(config_file)
            @logging = @config["logging"]
            @logger = Logger.new(log_device, logfile_count, logfile_size)
        rescue Errno::ENOENT
            $stderr.puts "missing config file #{config_file}"
            exit 1
        end

        #
        # General
        #
        FILE_LOCATION = '/var/www'.freeze

        def web_root
            @config["file_location"] || FILE_LOCATION
        end

        def log_device
            logging["use_stdout"] == true ? STDOUT : logging["logfile_path"]
        end

        def logfile_size
            if logging["file_size"]
                unit, quantity = @logging["file_size"].first
                quantity = quantity.to_i
                quantity.send(unit)
            else
                DEFAULT_LOGFILE_SIZE
            end
        end

        def logfile_count
            if logging["keep_files"]
                logging["keep_files"].to_i
            else
                DEFAULT_LOGFILE_COUNT
            end
        end

        def get_retention_threshold(backup_type)
            interval, quantity = @config["retention"][backup_type.to_s].first
            quantity = quantity.to_i + 1
            quantity.send(interval).ago
        end

        def retain_dailies_after
            get_retention_threshold(:daily)
        end

        def retain_incrementals_after
            get_retention_threshold(:incremental)
        end

        def retain_monthlies_after
            get_retention_threshold(:monthly)
        end

        def retain_weeklies_after
            get_retention_threshold(:weekly)
        end


        #
        # MySQL
        #

        def user
            mysql['user']
        end

        def password
            mysql['password']
        end

        def database
            mysql['database']
        end

        def bin_path
            mysql['bin_path']
        end

        def bin_log
            mysql['bin_log']
        end

        #
        # S3
        #

        def access_key_id
            s3['access_key_id']
        end

        def secret_access_key
            s3['secret_access_key']
        end

        def bucket
            s3['bucket']
        end

        def region
            s3['region']
        end

        def prefix
            s3['prefix']
        end

        private

        def mysql
            @config['mysql']
        end

        def s3
            @config['s3']
        end

        def default_config_file
            File.join "#{ENV['HOME']}", '.mys3ql'
        end
    end
end
