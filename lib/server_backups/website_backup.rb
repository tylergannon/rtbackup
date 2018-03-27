module ServerBackups
    class WebsiteBackup < BackupBase
        SNAPSHOT_PATH = Pathname('~/.var.www.backup.tar.snapshot.bin').expand_path

        def backup_filename
            "#{self.class.name.demodulize.underscore}.#{self.backup_type}.#{self.timestamp}.tgz"
        end

        def create_archive_command
            <<-EOF
                tar --create --listed-incremental=#{SNAPSHOT_PATH} --gzip --no-check-device \
                #{'--level=0' unless self.incremental?} \
                --file=#{self.backup_path} #{config.web_root}
            EOF
        end
    end
end
