require 'spec_helper'
RSpec.describe RLM::Setup::Activities do

  it_behaves_like 'RlmAttributeSetterExtensions'

  # Check that values are set correct
  specify('.rlm_module_name_for_config') { expect(described_class.rlm_module_name_for_config).to eq('activities') }
  specify('.required_entries_from_config') { expect(described_class.required_entries_from_config).to eq(['license', 'maintenance']) }
  specify('.to_create_classname_from_config') { expect(described_class.to_create_classname_from_config).to eq(::TimeEntryActivity)}

  describe '.all' do

    specify 'has activy entries' do
      expect(described_class.all.size).to eq(described_class.required_entries_from_config.size)
      expect(described_class.all.first).to be_kind_of(::TimeEntryActivity)
      expect(described_class.all.last).to be_kind_of(::TimeEntryActivity)
    end

  end


end