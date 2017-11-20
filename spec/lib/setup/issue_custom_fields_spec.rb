require 'spec_helper'
RSpec.describe RLM::Setup::IssueCustomFields do

  it_behaves_like 'RlmAttributeSetterExtensions'

  # Custom method to extend the default attributes here
  describe '.evaluated_additional_attributes' do
    specify do
      expect(described_class.evaluated_additional_attributes('license_price')).to eq({"field_format" => "float", "is_required" => true})
    end
  end

end