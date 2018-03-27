module ServerBackups
    class S3
        PROVIDER = 'AWS'.freeze
        attr_reader :config, :logger
        def initialize(config)
            @config = config
            @logger = config.logger
        end

        def s3
            @s3 ||= begin
                s = Fog::Storage.new(
                    :provider              => PROVIDER,
                    :aws_secret_access_key => @config.secret_access_key,
                    :aws_access_key_id     => @config.access_key_id,
                    :region                => @config.region
                )
                logger.info "Connected to S3"
                s
            end
        end

        def bucket
            @bucket ||= begin
                d = s3.directories.get @config.bucket
                raise "S3 bucket #{@config.bucket} not found" unless d  # create bucket instead (n.b. region/location)?

                logger.info "s3: opened bucket #{@config.bucket}"
                d
            end
        end

        def delete_files_not_newer_than(key, age)
            bucket.files.all(prefix: key).each do |file|
                unless file.last_modified.to_datetime > age
                    file.destroy
                end
            end
        end

        def exists?(path)
            !!bucket.files.head(path)
        end

        def destroy(key)
            return unless exists?(key)
            bucket.files.destroy(key)
        end

        def save(local_file_name, s3_key)
            if s3_key[-1] == '/'
                full_path = File.join(s3_key, File.basename(local_file_name))
            else
                full_path = s3_key
            end
            s3.sync_clock
            unless exists?(full_path)
                s3_file = bucket.files.create(
                    :key    => full_path,
                    :body   => File.open(local_file_name, 'rb'),
                    :public => false,
                    :options=> {
                        'Content-MD5' => md5of(local_file_name),
                        'x-amz-storage-class' => 'STANDARD_IA'
                    }
                )
                logger.info "s3: pushed #{local_file_name} to #{s3_key}"
                s3_file
            end
        end
      

        private
    
        def md5of(local_file_name)
            Digest::MD5.base64digest(File.read(local_file_name))
        end
    end
end