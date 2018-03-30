# frozen_string_literal: true

require 'spec_helper'

# Create a test scenario.
# Make a bucket called restore-test-bucket
# Make a project called my_test_app, and create a small database.
# Can use fixtures/www for the web app.

# Increment 1:
# Make a simple database
# Created a table called my_data
# Populate it with data.

# Increment 2 file changes:
# Created data.csv and README.markdown, added something to website.html.
#
#
# Backup files:
# Full Backup
#
# Incremental 2:
# mysql-bin.000034.2018-03-30T0000
# website_backup.incremental.2018-03-30T0000.tgz

# Increment 23File changes:
# data.csv deleted lines 4 & 5, added line 10.
# 4,Cally Nash
# 5,Solomon G. Newman
# 10,Fork &. Spoon
# Data changes: Insert 39-100
#
# website_backup.incremental.2018-03-30T0100.tgz
# mysql-bin.000035.2018-03-30T0100

# Increment 4 changes:
# Change first line of README.markdown
# Change line 10 of data.csv to 10,Fork &. Knife
# Add a line to website.html
#
# mysql-bin.000036.2018-03-30T0200
# website_backup.incremental.2018-03-30T0200.tgz

# Increment 5 changes:
# Accidentally screw everything up.
#
# website_backup.incremental.2018-03-30T0300.tgz
# mysql-bin.000037.2018-03-30T0300
#
# Then take full backup
# mysql_backup.daily.2018-03-30T0400.sql.gz
# website_backup.daily.2018-03-30T0400.tgz
#
# Then take incremental
#
# website_backup.incremental.2018-03-30T0500.tgz
# mysql-bin.000037.2018-03-30T0500

RSpec.describe ServerBackups::WebsiteRestore do
    # Backups are assumed to be in Singpore
    # But notice that the time zone is set to UTC to demonstrate
    # the freedom to change time zone as long as the time math is done correctly.
    describe 'Live scenario', :vcr do
        after do
            FileUtils.rm_rf 'spec/fixtures/www.backup' if File.exist?('spec/fixtures/www.backup')
        end
        let(:time_zone) { ServerBackups::Config.get_time_zone('UTC') }
        # Restore point is Mar 30 2018, 2:30 AM, UTC +800
        let(:restore_point) { time_zone.local(2018, 3, 29, 18, 30) }
        let(:restore) { described_class.new(config_path, working_dir, restore_point) }
        let(:working_dir) { Dir.mktmpdir }
        let(:expected_filenames) do
            %w[website_backup.daily.2018-03-29T2300.UTC+0800.tgz
               website_backup.incremental.2018-03-30T0000.UTC+0800.tgz
               website_backup.incremental.2018-03-30T0100.UTC+0800.tgz
               website_backup.incremental.2018-03-30T0200.UTC+0800.tgz]
        end

        it 'Selects the right files to restore.', :vcr do
            actual_filenames = restore.files_to_restore.map { |file| File.basename(file.key) }
            expect(actual_filenames).to eq(expected_filenames)
        end

        describe 'Actual restore of files' do
            before { restore.do_restore }
            # I'm just going to keep it simple and check the md5's of the files.
            it 'should have the correct version of data.csv' do
                expect(md5_of_fixture('www/data.csv')).to eq('t/vbj3DJtw4sgnBPyVBWZQ==')
            end

            it 'should have the correct version of README file' do
                expect(md5_of_fixture('www/README.markdown')).to eq('i/Vfe9tenjZU5djWoKBx+g==')
            end

            it 'should have the correct version of html file' do
                expect(md5_of_fixture('www/website.html')).to eq('FGQaFxMJcvaYjgVvIjyMqg==')
            end
        end
    end

    def md5_of_fixture(filename)
        File.open File.absolute_path(File.join('spec', 'fixtures', filename)) do |file|
            return Digest::MD5.base64digest file.read
        end
    end
end
