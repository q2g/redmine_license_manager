require 'spec_helper'

RSpec.describe RLM::Setup do

  specify '.yaml_config' do
    expect(described_class.yaml_config).to eq(YAML::load(File.open("#{Rails.root}/plugins/redmine_license_manager/config/rlm_settings.yml").read))
  end

  describe '.name_for' do
    specify 'with module_name' do
      expect(described_class.name_for('my class', current_module_scope: 'IssuesThing')).to eql("rlm-issuesthing-my-class")
    end

    specify 'without module_name' do
      expect(described_class.name_for('my class')).to eql("rlm-my-class")
    end
  end

  specify '.module_name' do
    expect(described_class.module_name).to eq("redmine_license_manager")
  end

end