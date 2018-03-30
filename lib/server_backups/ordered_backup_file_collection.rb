# frozen_string_literal: true

module ServerBackups
    class OrderedBackupFileCollection
        attr_reader :s3_collection
        def initialize(s3_collection)
            @s3_collection = s3_collection
        end

        def full_backup_for(restore_point)
            sorted(full_backups).reverse.find do |file|
                get_timestamp_from_s3_object(file) <= restore_point
            end
        end

        def full_backup_for(restore_point)
            sorted(full_backups).reverse.find do |file|
                get_timestamp_from_s3_object(file) <= restore_point
            end
        end

        def incremental_backups_for(restore_point)
            sorted eligible_incremental_backups(restore_point)
        end

        INCREMENTAL = /incremental/i
        def full_backups
            s3_collection.reject { |file| INCREMENTAL =~ file.key }
        end

        def incremental_backups
            @incremental_backups ||=
                sorted(s3_collection.select { |file| INCREMENTAL =~ file.key }).to_a
        end

        private

        TIMESTAMP_REGEXP = /(\d{4})-(\d{2})-(\d{2})T(\d{2})00/
        def get_timestamp_from_s3_object(s3_object)
            Time.zone.local(*TIMESTAMP_REGEXP.match(s3_object.key).captures)
        end

        def sorted(coll)
            coll.sort_by { |file| get_timestamp_from_s3_object file }
        end

        def eligible_incremental_backups(restore_point)
            full_backup_timestamp = get_timestamp_from_s3_object full_backup_for(restore_point)
            incremental_backups.select do |file|
                get_timestamp_from_s3_object(file) > full_backup_timestamp &&
                    get_timestamp_from_s3_object(file) <= restore_point
            end
        end
    end
end
