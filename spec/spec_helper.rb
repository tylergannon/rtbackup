# frozen_string_literal: true

require 'bundler/setup'
require 'server_backups'
require 'active_support'
require 'active_support/testing/time_helpers'
require 'vcr'
require 'tmpdir'
require 'fileutils'

RSpec.shared_context 'Global helpers' do
    let(:config_path) do
        # File.join(File.dirname(__FILE__), 'fixtures', 'test_conf.yml')
        fixture('test_conf.yml')
    end
    let(:config) do
        ServerBackups::Config.new(config_path)
    end

    def fixture(name)
        File.join(File.dirname(__FILE__), 'fixtures', name)
    end
end

RSpec.configure do |config|
    # Enable flags like --only-failures and --next-failure
    Time.zone = 'UTC'
    VCR.configure do |vcr_conf|
        vcr_conf.cassette_library_dir = 'spec/fixtures/vcr_cassettes'
        vcr_conf.hook_into :webmock
        vcr_conf.configure_rspec_metadata!
        # vcr_conf.record_mode = :all
        vcr_conf.default_cassette_options = {
            record: :once
        }
    end

    config.example_status_persistence_file_path = '.rspec_status'

    config.include_context 'Global helpers'

    # Disable RSpec exposing methods globally on `Module` and `main`
    config.disable_monkey_patching!
    config.include ActiveSupport::Testing::TimeHelpers

    config.expect_with :rspec do |c|
        c.syntax = :expect
    end
end
