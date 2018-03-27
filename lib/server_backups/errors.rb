module ServerBackups
    class BackupCreationError < StandardError
        attr_reader :backup_class, :backup_type
        def initialize(msg, backup_class, backup_type)
            @backup_class = backup_class
            @backup_type = backup_type
            super(msg)
        end
    end
end
