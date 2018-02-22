module RLM
  module IssueExtension
    
    extend ActiveSupport::Concern
    
    included do
      before_validation :set_license_auto_subject, :set_maintainance_price, if: :is_license_or_extension?
      before_validation :load_parent_values,  if: :is_license_extension?
      before_save :check_parent_issue_tracker, :load_parent_values,  if: :is_license_extension?
      
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
      
      attr_accessor :skip_parent_callbacks
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
        self.custom_field_values = { ::RLM::Setup::IssueCustomFields.send(cf_name).id => val}
        self.skip_parent_callbacks = true
        self.save
      end
    end
    
    def create_splitted_license(n=1)
      ratio = n/self.license_count.to_f
      new_count = self.license_count.to_i - n
      
      cloned_values = self.attributes.slice('tracker_id', 'project_id', 'category_id', 'author_id', 'parent_id', 'root_id')
      
      cloned_values[:license_count] = n
      
      %w(maintainance_date maintainance_paid_until maintainance_invoice_received maintainance_period customer_invoice_reference license_product_name serialnumber controlnumber license_lef).each do |v|
        cloned_values[v.to_sym] = self.send(v)
      end
      
      %w(license_price license_purchase_price maintainance_price maintainance_purchase_price).each do |p|
        cloned_values[p.to_sym] = self.send(p).to_f*ratio
        self.send("#{p}=", self.send(p).to_f*(1-ratio))
      end
      
      new_license = Issue.new(cloned_values)
      new_license.send(:set_license_auto_subject)
      new_license.subject = "#{self.subject} [Split #{n}]" if new_license.subject.blank?
      if new_license.save
        self.save
      end
    end  
    
    private
    def set_license_auto_subject
      return if self.license_product_name.blank? || self.license_product_name == "-"
      
      auto_subject = self.license_product_name.presence.dup
      
      if auto_subject.match('[X]') && self.license_count.blank?
        self.errors.add(:license_count, I18n.t('rlm.errors.license_count_blank'))
        return false
      else  
        
        if self.license_count.present? && auto_subject.present?
          auto_subject = auto_subject.gsub("[X]", self.license_count.to_s)
        end
      
        self.subject = auto_subject if auto_subject.present?
      end  
    end
    
    def set_maintainance_price
      lp = self.custom_field_values.detect {|f| f.custom_field.internal_name == ::RLM::Setup::IssueCustomFields.license_price.internal_name }
      mp = self.custom_field_values.detect {|f| f.custom_field.internal_name == ::RLM::Setup::IssueCustomFields.maintainance_price.internal_name }
      mp.value = (lp.value.to_f*0.2).to_s if mp.value.blank?
      
      lp_p = self.custom_field_values.detect {|f| f.custom_field.internal_name == ::RLM::Setup::IssueCustomFields.license_purchase_price.internal_name }
      mp_p = self.custom_field_values.detect {|f| f.custom_field.internal_name == ::RLM::Setup::IssueCustomFields.maintainance_purchase_price.internal_name }
      mp_p.value = (lp_p.value.to_f*0.2).to_s if mp_p.value.blank?
    end
    
    def check_parent_issue_tracker
      return if skip_parent_callbacks
      if self.parent.nil?
        self.errors.add(:tracker_id, I18n.t('rlm.errors.no_parent_found'))
        return false
      elsif !self.parent.is_license?
        self.errors.add(:tracker_id, I18n.t('rlm.errors.parent_not_a_license'))
        return false
      else
        return true
      end
    end
    
    def load_parent_values
      return if skip_parent_callbacks
      if self.parent || self.parent_issue_id.present?
        if self.parent.nil?
          self.parent = Issue.find(self.parent_issue_id)
        end
        
        self.maintainance_date   = self.parent.maintainance_date   if self.maintainance_date.blank?
        self.maintainance_period = self.parent.maintainance_period if self.maintainance_period.blank?  
      end
    end
    
    
    
  end
end