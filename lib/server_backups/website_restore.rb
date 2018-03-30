# frozen_string_literal: true

require 'English'

module ServerBackups
    class WebsiteRestore < RestoreBase
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

        def s3_prefix
            File.join(config.prefix, 'website_backup', '/')
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
    end
end
