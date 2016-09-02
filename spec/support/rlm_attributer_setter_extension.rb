RSpec.shared_examples "RlmAttributeSetterExtensions" do

  specify('.rlm_module_name_for_config') do
    expect(described_class.rlm_module_name_for_config).to eq(described_class.name.split('::').last.underscore)
  end

  specify('.required_entries_from_config') do
    expect(described_class.required_entries_from_config).to eq(RLM::Setup.yaml_config['modules']['setup'][described_class.rlm_module_name_for_config]['entries'])
  end

  specify('.to_create_classname_from_config') do
    expect(described_class.to_create_classname_from_config).to eq(RLM::Setup.yaml_config['modules']['setup'][described_class.rlm_module_name_for_config]['class_name'].constantize)
  end

  described_class.required_entries_from_config.each do |entry_name|
    describe ".#{entry_name}" do

      let(:entry) { described_class.to_create_classname_from_config.new }

      context 'create a new entry' do
        before do
          expect(described_class.to_create_classname_from_config).to receive(:find_or_initialize_by).with(
            described_class.identify_column.to_sym => RLM::Setup.name_for(entry_name, current_module_scope: described_class.rlm_module_name_for_config)).and_return(entry)
          expect(entry).to receive(:new_record?).and_return(true)
          expect(entry).to receive('name=').with(I18n.t("rlm.entries.#{described_class.rlm_module_name_for_config}.#{entry_name}"))
          expect(entry).to receive(:save)
        end

        specify { expect(described_class.send(entry_name)).to  eq(entry) }

      end

    end
  end

end