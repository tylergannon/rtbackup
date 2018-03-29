# frozen_string_literal: true

require 'spec_helper'

COLLECTION_CASSETTE = 'ServerBackups::OrderedBackupFileCollection/selecting files'

RSpec.describe ServerBackups::OrderedBackupFileCollection do
    let(:s3) { ServerBackups::S3.new(config) }
    let(:restore_point) { Time.parse('Mar 28, 2018 20:42:06 PM GMT+0700') }
    let(:working_dir) { Dir.mktmpdir }
    after { FileUtils.remove_entry(working_dir) }

    let(:full_backup_key) do
        'my_test_app/website_backup/daily/website_backup.daily.2018-03-28T0900.tgz'
    end

    describe 'selecting files' do
        let(:collection) { s3.get_ordered_collection('my_test_app/website_backup/') }
        describe 'Full Backup' do
            subject { collection.full_backup_for(restore_point) }
            it 'should be the latest one before the restore point in time' do
                VCR.use_cassette COLLECTION_CASSETTE do
                    expect(File.basename(subject.key)).to \
                        eq('website_backup.daily.2018-03-28T0900.tgz')
                end
            end
        end
        describe 'Incremental Backups' do
            subject { collection.incremental_backups_for(restore_point) }
            it 'should have four items' do
                VCR.use_cassette COLLECTION_CASSETTE do
                    expect(subject.length).to be(4)
                end
            end
            let(:subject_filenames) { subject.map { |object| File.basename(object.key) } }
            let(:expected_filenames) do
                %w[
                    website_backup.incremental.2018-03-28T1000.tgz
                    website_backup.incremental.2018-03-28T1100.tgz
                    website_backup.incremental.2018-03-28T1200.tgz
                    website_backup.incremental.2018-03-28T1300.tgz
                ]
            end
            it 'should have these items' do
                VCR.use_cassette COLLECTION_CASSETTE do
                    expect(subject_filenames).to eq(expected_filenames)
                end
            end
        end
    end
end
