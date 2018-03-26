module ServerBackups
    class BackupBase
        attr_reader :working_directory, :config, :logger, :s3
    
        TIMESTAMP_FORMAT = '%Y-%m-%dT%H00'.freeze
    
        def initialize(config_file, working_directory)
            @working_directory = working_directory
            @config = Config.new(config_file)
            @logger = config.logger
        end
    
        def run
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
            @s3 = S3.new self.config
        end
    end    
end