require 'spec_helper'
RSpec.describe RLM::Setup::Trackers do

  it_behaves_like 'RlmAttributeSetterExtensions'

  describe 'default_status_id is set' do
    specify do
      described_class.all.each do |tracker|
        expect(tracker.default_status_id).to eq(RLM::Setup::IssueStatuses.license_inactive.id)
      end
    end
  end


end