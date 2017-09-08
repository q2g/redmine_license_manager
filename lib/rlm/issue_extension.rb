module RLM
  module IssueExtension
    
    extend ActiveSupport::Concern
    
    included do
      before_validation :set_license_auto_subject, if: :is_license_or_extension?
      
      def self.find_by_serialnumber(serial)
        find_by_custom_field_value(serial, ::RLM::Setup::IssueCustomFields.serialnumber.id)
      end
      
      def self.find_by_license_product_name(product_name)
        find_by_custom_field_value(product_name, ::RLM::Setup::IssueCustomFields.license_product_name.id)
      end
      
      def self.find_by_custom_field_value(value, cf_id)
        self.joins("LEFT JOIN custom_values on customized_id = issues.id")
          .where("custom_values.customized_type = 'Issue' AND custom_values.custom_field_id = #{cf_id}")
          .where("lower(custom_values.value) LIKE '%#{value.to_s.downcase}%'")
      end
      
    end
    
    def is_license?
      self.tracker_id == ::RLM::Setup::Trackers.license.id
    end
    
    def is_license_extension?
      self.tracker_id == ::RLM::Setup::Trackers.license_extension.id
    end
    
    def is_license_or_extension?
      is_license? || is_license_extension?
    end
    
    # accessing custom fields
    # generating handy getters and setters
    RLM::Setup::IssueCustomFields.required_entries_from_config.each do |cf_name|
      
      define_method(cf_name) do
        self.custom_field_value(::RLM::Setup::IssueCustomFields.send(cf_name).id)
      end
      
      define_method("#{cf_name}=") do |val|
        self.custom_value_for(::RLM::Setup::IssueCustomFields.send(cf_name).id).value = val
      end
    end
    
    private
    def set_license_auto_subject
      auto_subject = self.license_product_name.presence.dup
      
      return if self.license_product_name.blank? || self.license_product_name == "-"
      
      if self.license_count.present? && auto_subject.present?
        auto_subject = auto_subject.gsub("[X]", self.license_count.to_s)
      end
      
      self.subject = auto_subject if auto_subject.present?
    end
    
  end
end