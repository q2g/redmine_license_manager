require 'spec_helper'
RSpec.describe RLM::Setup::Activities do

  it_behaves_like 'RlmAttributeSetterExtensions'

  # Check that values are set correct
  specify('.rlm_module_name_for_config') { expect(described_class.rlm_module_name_for_config).to eq('activities') }
  specify('.required_entries_from_config') { expect(described_class.required_entries_from_config).to eq(['license', 'maintenance']) }
  specify('.to_create_classname_from_config') { expect(described_class.to_create_classname_from_config).to eq(::TimeEntryActivity)}

  describe '.license' do

    let(:entry) { described_class.to_create_classname_from_config.new }

    context 'create a new entry' do
      before do
        expect(described_class.to_create_classname_from_config).to receive(:find_or_initialize_by).with(
          described_class.identify_column.to_sym => RLM::Setup.name_for('license', current_module_scope: described_class.rlm_module_name_for_config)).and_return(entry)
        expect(entry).to receive(:new_record?).and_return(true)
        expect(entry).to receive('name=').with('License')
        expect(entry).to receive(:save)
      end

      specify { expect(described_class.license).to eq(entry) }

    end

  end


end