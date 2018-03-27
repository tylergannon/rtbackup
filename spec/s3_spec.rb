require 'spec_helper'
require 'yaml'

RSpec.describe ServerBackups::S3 do
    subject {ServerBackups::S3.new(config)}
    # before {travel_to Time.zone.local(2018, 3, 26)}
    # after {travel_back}

    describe "Connecting to bucket" do
        it "Gets the bucket using SDK", :vcr, record: :all do
            q = Aws::S3::Bucket.new('tyler-backup-test', client: subject.client)
        end

        it "Can access bucket", :vcr do
            expect(subject.bucket.name).to eq('tyler-backup-test')
        end

        let(:key) {'/some/prefix/'}
        let(:filename) {'little_file.txt'}
        let(:path) {File.join(key, filename)}

        it "Can store and remove a file", :vcr do
            subject.save(fixture(filename), key)
            expect(subject.exists?(path)).to be_truthy
            subject.destroy(path)
            expect(subject.exists?(path)).to be_falsey
        end
    end

    let(:config_yaml) do
        YAML::load_file(config_path)
    end
end
