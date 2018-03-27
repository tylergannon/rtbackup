require 'spec_helper'
require 'yaml'
require 'fileutils'
require 'tmpdir'

RSpec.describe ServerBackups::BackupBase do
    let(:working_dir) {Dir.mktmpdir}
    after {FileUtils.remove_entry(working_dir)}
    subject {ServerBackups::WebsiteBackup.daily(config_path, working_dir)}

    describe "Daily Backup" do
        it "Has the correct back file name" do
            travel_to Time.zone.local(2018, 03, 27, 14) do
                expect(subject.backup_filename).to eq('website_backup.daily.2018-03-27T1400.tgz')
            end
        end
        it "Has the correct storage prefix" do
            expect(subject.s3_prefix).to eq("my_test_app/website_backup/daily/")
        end

        it "Backs up the file to the s3 bucket", :vcr do
            travel_to Time.zone.local(2018, 03, 27, 17) do
                subject.do_backup
                expect(File.exists?(File.join(working_dir, subject.backup_filename)))
                expect(subject.s3.exists?(subject.backup_s3_key))
                file = subject.s3.bucket.objects(prefix: subject.backup_s3_key).first
                # expect(file.content_length).to eq(261)
                subject.s3.delete_files_not_newer_than(subject.backup_s3_key, 1.minute.from_now)
                expect(subject.s3.exists?(subject.backup_s3_key)).not_to be_truthy
            end
        end
    end
end
