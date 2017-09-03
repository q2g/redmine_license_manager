module RLM
  class Setup

    cattr_reader :yaml_config

    class << self

      def yaml_config
        if @@yaml_config.nil?
          config_path = File.expand_path("../../../config/rlm_settings.yml", __FILE__)
          @@yaml_config = YAML::load(File.open(config_path).read)
        end

        @@yaml_config
      end

      def name_for(name, current_module_scope: nil)
        [naming_prefix, current_module_scope.try(:parameterize), name.parameterize].compact.join("-")
      end

      def module_name
        yaml_config['module_name']
      end

      def naming_prefix
        yaml_config['naming_prefix']
      end

      def permissions_config
        yaml_config['modules']['permissions']
      end

    end

    module RlmAttributeSetterExtensions

      extend ActiveSupport::Concern

      included do |base|

        cattr_reader :to_create_classname_from_config
        cattr_reader :identify_column_from_config

        # Get Ident key from 'rlm_settings.yml' based on the class the module is included in
        def self.rlm_module_name_for_config
          self.name.split('::').last.underscore
        end

        def self.required_entries_from_config
          Setup.yaml_config['modules']['setup'][rlm_module_name_for_config]['entries']
        end

        def self.to_create_classname_from_config
          @@to_create_classname_from_config = Setup.yaml_config['modules']['setup'][rlm_module_name_for_config]['class_name'].constantize
        end

        def self.identify_column
          Setup.yaml_config['modules']['setup'][rlm_module_name_for_config]['identify_column']
        end

        def self.human_entry_name(entry_name, locale: I18n.locale)
          # truncated name as redmine mostly allows only 30 chars as name
          n = I18n.t(entry_name, scope: "rlm.entries.#{rlm_module_name_for_config}", locale: locale.to_s.downcase.to_sym)
          return n.last(30)
        end

        def self.default_data_attributes(entry_name)
          { identify_column => Setup.name_for(entry_name, current_module_scope: self.rlm_module_name_for_config) }
        end

        def self.evaluated_additional_attributes(entry_name)
          data_attributes = {}

          if Setup.yaml_config['modules']['setup'][rlm_module_name_for_config]['additional_attributes'].to_a.any?
            Setup.yaml_config['modules']['setup'][rlm_module_name_for_config]['additional_attributes'].each do |attribute_name, to_evaluate_value|
              data_attributes.merge!(attribute_name => eval(to_evaluate_value))
            end
          end

          return data_attributes
        end

        def self.combined_data_attributes(entry_name)
          default_data_attributes(entry_name).merge(evaluated_additional_attributes(entry_name))
        end


        def self.all
          self.required_entries_from_config.map {|e| self.send e }
        end

        # Dynamically defining the getter/Setter method base on the settings in yaml file
        self.required_entries_from_config.each do |entry_name|
          (class << base; self end).class_eval do
            define_method entry_name do

              t = to_create_classname_from_config.find_or_initialize_by(combined_data_attributes(entry_name))

              if t.new_record?
                t.name = human_entry_name(entry_name)
                t.save
              end

              return t
            end
          end
        end

      end

    end

    class Activities; include RlmAttributeSetterExtensions; end

    module Trackers; include RlmAttributeSetterExtensions; end

    module IssueStatuses; include RlmAttributeSetterExtensions; end

    module IssueCustomFields
      include RlmAttributeSetterExtensions

      class << self
        def evaluated_additional_attributes(entry_name)
          Setup.yaml_config['modules']['setup'][rlm_module_name_for_config]['entry_settings'][entry_name].merge({'editable' => false})
        end
      end

    end

    module Projects

      class << self

        def license_manager_projects
          ::Project.has_module(Setup.module_name)
        end

        def default_license_manager_project
          if license_manager_projects.any?
            license_manager_projects.first
          else
            # Setup an inital Project
            project = ::Project.create(name: "Redmine License Manager #{Time.now.to_i}")

            convert_to_license_manager_project!(project)

            return license_manager_projects.first
          end
        end

        def convert_to_license_manager_project!(project)
          # Checking what needs to be done
          status = check_license_manager_project_integrity(project)

          ::EnabledModule.create(project_id: project.id, name: Setup.module_name) if status[:module] == false

          # Reset/Assign Trackers
          project.trackers = Trackers.all if status[:trackers] == false

          # Reset/Assign Activities
          project.time_entry_activities = Activities.all if status[:activities] == false

          # Add eventually missing issue custom fields to the project
          project.issue_custom_fields += IssueCustomFields.all if status[:issue_custom_fields] == false

          project.save

          return project
        end

        def check_license_manager_project_integrity(project)
          status = {}
          status[:module]               = project.module_enabled?(Setup.module_name)
          status[:trackers]             = (project.trackers == Trackers.all)
          status[:activities]           = (project.time_entry_activities == Activities.all)

          # allow more than the default setup up custom fields
          status[:issue_custom_fields]  = (IssueCustomFields.all - project.issue_custom_fields).empty?
          status[:valid]                = !status.values.include?(false)

          return status
        end

      end

    end

  end
end
