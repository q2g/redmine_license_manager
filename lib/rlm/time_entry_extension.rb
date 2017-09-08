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
        self.custom_field_values = {::RLM::Setup::TimeEntryCustomFields.send(cf_name).id => val}
        self.save(validate: false) # => to make shure the custom field value is stored at any case
      end
    end
    
  end
end