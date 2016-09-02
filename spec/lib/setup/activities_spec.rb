require 'spec_helper'
RSpec.describe RLM::Setup::Activities do

  it_behaves_like 'RlmAttributeSetterExtensions'

  specify('.rlm_module_name_for_config') { expect(described_class.rlm_module_name_for_config).to eq('activities') }

end