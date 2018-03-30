# frozen_string_literal: true

RSpec.describe ServerBackups do
    it 'has a version number' do
        expect(ServerBackups::VERSION).not_to be nil
    end

    # it 'is all in UTC' do
    #     expect(Time.zone.name).to eq('UTC')
    # end
end
