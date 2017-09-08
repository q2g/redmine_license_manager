module RLM
  module TimeEntryExtension
    
    extend ActiveSupport::Concern
    
    # accessing custom fields
    # generating handy getters and setters
    RLM::Setup::TimeEntryCustomFields.required_entries_from_config.each do |cf_name|
      
      define_method(cf_name) do
        self.custom_field_value(::RLM::Setup::TimeEntryCustomFields.send(cf_name).id)
      end
      
      define_method("#{cf_name}=") do |val|
        self.custom_value_for(::RLM::Setup::TimeEntryCustomFields.send(cf_name).id).value = val
      end
    end
    
  end
end