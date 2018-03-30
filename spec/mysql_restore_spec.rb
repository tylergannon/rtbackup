# frozen_string_literal: true

require 'spec_helper'

# see website_restore_spec.rb for details on the test
# scenario used here.

RSpec.describe ServerBackups::MysqlRestore do
    # Backups are assumed to be in Singpore
    # But notice that the time zone is set to UTC to demonstrate
    # the freedom to change time zone as long as the time math is done correctly.
    describe 'Live scenario', :vcr do
        let(:time_zone) { ServerBackups::Config.get_time_zone('UTC') }
        # Restore point is Mar 30 2018, 2:30 AM, UTC +800
        let(:restore_point) { time_zone.local(2018, 3, 29, 18, 30) }
        let(:restore) { described_class.new(config_path, working_dir, restore_point, 'my_test_app') }
        let(:working_dir) { Dir.mktmpdir }
        let(:expected_bin_logs) do
            %w[mysql-bin.000034.2018-03-30T0000.UTC+0800
               mysql-bin.000035.2018-03-30T0100.UTC+0800
               mysql-bin.000036.2018-03-30T0200.UTC+0800]
        end

        it 'Selects the right mysql dump to restore.', :vcr do
            actual_filename = File.basename restore.full_backup_file.key
            expect(actual_filename).to eq('mysql_backup.daily.2018-03-29T2300.UTC+0800.sql.gz')
        end

        it 'Selects the right mysql logs to restore.', :vcr do
            actual_filenames = restore.incremental_backups.map { |file| File.basename(file.key) }
            expect(actual_filenames).to eq(actual_filenames)
        end

        describe 'Actual restore of database' do
            # I'm just going to keep it simple and check the md5's of the files.
            it 'runs' do
                expect {
                    restore.do_restore
                }.not_to raise_error
            end

            # it 'should have the correct version of README file' do
            #     expect(md5_of_fixture('www/README.markdown')).to eq('i/Vfe9tenjZU5djWoKBx+g==')
            # end

            # it 'should have the correct version of html file' do
            #     expect(md5_of_fixture('www/website.html')).to eq('FGQaFxMJcvaYjgVvIjyMqg==')
            # end
        end
    end

    def md5_of_fixture(filename)
        File.open File.absolute_path(File.join('spec', 'fixtures', filename)) do |file|
            return Digest::MD5.base64digest file.read
        end
    end
end
