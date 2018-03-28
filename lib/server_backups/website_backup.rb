# frozen_string_literal: true

module ServerBackups
    class WebsiteBackup < BackupBase
        SNAPSHOT_PATH = Pathname('~/.var.www.backup.tar.snapshot.bin').expand_path

        def restore(datetime); end

        def backup_filename
            "#{self.class.name.demodulize.underscore}.#{backup_type}.#{timestamp}.tgz"
        end

        def create_archive_command
            <<-EOF
                tar --create --listed-incremental=#{SNAPSHOT_PATH} --gzip --no-check-device \
                #{'--level=0' unless incremental?} \
                --file=#{backup_path} #{config.web_root}
            EOF
        end
    end
end
