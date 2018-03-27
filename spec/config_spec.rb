require 'spec_helper'
require 'yaml'

RSpec.describe ServerBackups::Config do
    describe "retention times" do
        before do
            travel_to Time.zone.local(2004, 11, 24, 01, 04, 44)
        end
        after do
            travel_back
        end
        it "should give one more than the given days" do
            expect(config.retain_dailies_after).to eq(7.days.ago)
        end
        it "should give one more than the given hours" do
            expect(config.retain_incrementals_after).to eq(145.hours.ago)
        end
        it "should give one more than the given weeks" do
            expect(config.retain_weeklies_after).to eq(4.weeks.ago)
        end
        it "should give one more than the given months" do
            expect(config.retain_monthlies_after).to eq(12.months.ago)
        end
    end

    describe "Logging" do
        it " should not be configured to use STDOUT" do
            pending "Turn this on later"
            expect(config.log_device).to eq("/tmp/server_backup.log")
        end
    end

    let(:config_yaml) do
        YAML::load_file(config_path)
    end
end
