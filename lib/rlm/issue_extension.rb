module RLM
  module IssueExtension
    
    extend ActiveSupport::Concern
    
    included do
      before_validation :set_license_auto_subject, if: :is_license_or_extension?
      
      def self.find_by_serial_number(serial)
        find_by_custom_field_value(serial, ::RLM::Setup::IssueCustomFields.serial_number.id)
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
    def license_product_name
      self.custom_field_value(::RLM::Setup::IssueCustomFields.license_product_name.id)
    end
    
    def license_count
      self.custom_field_value(::RLM::Setup::IssueCustomFields.license_count.id)
    end
    
    def lef
      self.custom_field_value(::RLM::Setup::IssueCustomFields.lef.id)
    end
    
    def serial_number
      self.custom_field_value(::RLM::Setup::IssueCustomFields.serial_number.id)
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