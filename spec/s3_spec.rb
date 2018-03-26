require 'spec_helper'
require 'yaml'

RSpec.describe ServerBackups::S3 do
    subject {ServerBackups::S3.new(config)}
    # before {travel_to Time.zone.local(2018, 3, 26)}
    # after {travel_back}

    describe "Connecting to bucket" do
        it "Can access bucket", :vcr do
            expect(subject.bucket.identity).to eq('myapp-backup-test')
        end

        let(:key) {'/some/prefix/'}
        let(:filename) {'little_file.txt'}
        let(:path) {File.join(key, filename)}

        it "Can store and remove a file", :vcr do
            subject.save(fixture(filename), key)
            # puts subject.bucket.files.methods.sort
            # puts subject.bucket.files.all(prefix: path)[0].last_modified.to_datetime > 1.days.ago
            expect(subject.exists?(path)).to be_truthy
            subject.destroy(path)
            expect(subject.exists?(path)).to be_falsey
        end
    end

    let(:config_yaml) do
        YAML::load_file(config_path)
    end
end
