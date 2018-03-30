# frozen_string_literal: true

require 'spec_helper'

COLLECTION_CASSETTE = 'ServerBackups::OrderedBackupFileCollection/selecting files'

RSpec.describe ServerBackups::OrderedBackupFileCollection do
    let(:s3) { ServerBackups::S3.new(config) }
    let(:working_dir) { Dir.mktmpdir }
    after { FileUtils.remove_entry(working_dir) }
    let(:time_zone) { ServerBackups::Config.get_time_zone('UTC') }
    # Restore point is Mar 30 2018, 2:30 AM, UTC +800
    let(:restore_point) { time_zone.local(2018, 3, 29, 18, 30) }

    let(:full_backup_key) do
        'my_test_app/website_backup/daily/website_backup.daily.2018-03-28T0900.tgz'
    end

    describe 'selecting files', :vcr do
        let(:collection) { s3.get_ordered_collection('my_test_app/website_backup/') }
        describe 'Full Backup' do
            subject { collection.full_backup_for(restore_point) }
            it 'should be the latest one before the restore point in time' do
                expect(collection.full_backups.length).to be(2)
                expect(File.basename(subject.key)).to \
                    eq('website_backup.daily.2018-03-29T2300.UTC+0800.tgz')
            end
        end
        describe 'Incremental Backups' do
            subject { collection.incremental_backups_for(restore_point) }
            it 'should have three items' do
                expect(subject.length).to be(3)
            end
            let(:subject_filenames) { subject.map { |object| File.basename(object.key) } }
            let(:expected_filenames) do
                %w[
                    website_backup.incremental.2018-03-30T0000.UTC+0800.tgz
                    website_backup.incremental.2018-03-30T0100.UTC+0800.tgz
                    website_backup.incremental.2018-03-30T0200.UTC+0800.tgz
                ]
            end
            it 'should have these items' do
                expect(subject_filenames).to eq(expected_filenames)
            end
        end
    end
end
