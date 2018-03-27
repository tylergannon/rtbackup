require 'aws-sdk-s3'

module ServerBackups
    class S3
        PROVIDER = 'AWS'.freeze
        attr_reader :config, :logger
        def initialize(config)
            @config = config
            @logger = config.logger
        end

        def client
            @client ||= begin
                Aws.config[:credentials] = Aws::Credentials.new(
                    config.access_key_id, config.secret_access_key
                )
                Aws::S3::Client.new region: config.region
            end
        end

        def bucket
            @bucket ||= Aws::S3::Bucket.new(config.bucket, client: client)
        end

        def delete_files_not_newer_than(key, age)
            bucket.objects(prefix: key).each do |file|
                unless file.last_modified.to_datetime > age
                    destroy key, true
                end
            end
        end

        def exists?(path)
            logger.debug "Exists? #{config.bucket}  #{path}"
            !bucket.objects(prefix: path).to_a.empty?
            # !!client.head_object(bucket: config.bucket, key: path)
        end

        def destroy(key, existence_known=false)
            return unless existence_known || exists?(key)
            client.delete_object bucket: config.bucket, key: key
        end
        
        def save(local_file_name, s3_key)
            if s3_key[-1] == '/'
                full_path = File.join(s3_key, File.basename(local_file_name))
            else
                full_path = s3_key
            end

            return if exists?(full_path)
            file = Aws::S3::Object.new(config.bucket, full_path, client: client)
            file.put(
                acl: 'private',
                body: File.open(local_file_name, 'rb'),
                content_md5: md5of(local_file_name),
                storage_class: 'STANDARD_IA'
            )
        end
      

        private
    
        def md5of(local_file_name)
            Digest::MD5.base64digest(File.read(local_file_name))
        end
    end
end