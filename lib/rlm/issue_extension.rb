module RLM
  module IssueExtension
    
    extend ActiveSupport::Concern
    
    included do
      before_validation :set_license_auto_subject, if: :is_license_or_extension?
      
      def self.lef_from_serial_number(serial)
        entries = self.joins("LEFT JOIN custom_values on customized_id = issues.id")
          .where("custom_values.customized_type = 'Issue' AND custom_values.custom_field_id = #{::RLM::Setup::IssueCustomFields.serial_number.id}")
          .where("custom_values.value = '#{serial}'").first
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
    
    private
    def set_license_auto_subject
      auto_subject = self.license_product_name.presence.dup
      if self.license_count.present? && auto_subject.present?
        auto_subject = auto_subject.gsub("[X]", self.license_count.to_s)
      end
      
      self.subject = auto_subject if auto_subject.present?
    end
    
  end
end