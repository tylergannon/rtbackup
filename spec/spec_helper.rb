# frozen_string_literal: true

require 'bundler/setup'
require 'server_backups'
require 'active_support'
require 'active_support/testing/time_helpers'
require 'vcr'

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
    VCR.configure do |config|
        config.cassette_library_dir = 'spec/fixtures/vcr_cassettes'
        config.hook_into :webmock
        config.configure_rspec_metadata!
        # config.record_mode = :all
        config.default_cassette_options = {
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
