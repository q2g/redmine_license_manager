RSpec.shared_examples "RlmAttributeSetterExtensions" do

  specify('.rlm_module_name_for_config') do
    expect(described_class.rlm_module_name_for_config).to eq(described_class.name.split('::').last.underscore)
  end

  specify('.required_entries_from_config') do
    expect(described_class.required_entries_from_config).to eq(RLM::Setup.yaml_config['modules']['setup'][described_class.rlm_module_name_for_config]['entries'])
  end

  specify('.required_entries_from_config') do
    expect(described_class.required_entries_from_config).to eq(RLM::Setup.yaml_config['modules']['setup'][rlm_module_name_for_config]['entries'])
  end


end