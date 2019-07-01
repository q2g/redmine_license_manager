namespace :rlm do
  namespace :setup do

    desc "Check if all required Components (Trackers, IssueStatuses, Activities, IssueCustomFields...) are set up"
    task :status => :environment do
      RLM::Setup.yaml_config['modules']['setup'].each do |component_name, settings|

        component_class = settings['class_name'].constantize
        setup_module    = "RLM::Setup::#{component_name.camelize}".constantize

        puts "Checking #{settings['class_name']}"

        settings['entries'].each do |entry_name|
          internal_name = RLM::Setup.name_for(entry_name, current_module_scope: setup_module.rlm_module_name_for_config)

          entry = component_class.find_by(setup_module.default_data_attributes(entry_name))

          output = [".. #{internal_name}"]

          if entry.nil?
            output << "[MISSING]"
          else
            output << "[EXISTS]"
          end

          puts output.join(" ")

          #checking attributes
          if entry.present?
            warn = "   [WARN]"
            setup_module.combined_data_attributes(entry_name).each do |key, value|
              if entry[key] != value && key != 'possible_values'
                puts "#{warn}: attribute '#{key}' is #{entry[key].inspect} - should be #{value.inspect}"
              end
            end
          end

        end

        puts "---------------------\n"
      end
    end

    desc "Setup required Trackers, CustomFields, Status for License Manager"
    task :run => :environment do
      # Setting up activities
      RLM::Setup::Activities.all

      # Setting up trackers
      trackers = RLM::Setup::Trackers.all

      # Setting up Custom fields for Issue
      RLM::Setup::IssueCustomFields.all.each do |custom_field|
        custom_field.trackers = trackers
        custom_field.save
      end

      # Setting up Custom fields for Issue
      RLM::Setup::TimeEntryCustomFields.all.each do |custom_field|
        # custom_field.trackers = trackers
#         custom_field.save
      end

      # Setting up Issue Status
      RLM::Setup::IssueStatuses.all
    end

    #namespace :projects do
    #
    #  desc "Creates a default license manager project if it is missing"
    #  task :create_default => :environment do
    #    if RLM::Setup::Projects.license_manager_projects.any?
    #      project = RLM::Setup::Projects.default_license_manager_project
    #      puts "Default License Manager Project is: #{project.name} (ID: #{project.id})".colorize(:yellow)
    #      puts ".. checking integrity"
    #
    #      status = RLM::Setup::Projects.check_license_manager_project_integrity(project)
    #      if status == true
    #        puts ".. STATUS OK".colorize(:green)
    #      else
    #        puts ".. STATUS NOT OK".colorize(:red)
    #        puts "=> Please run 'rake rlm:setup:projects:convert_to_license_manager_project PROJECT_ID=#{project.id}' to setup data!"
    #      end
    #    else
    #      puts "Creating default Default License Manager Project"
    #      project = RLM::Setup::Projects.default_license_manager_project
    #      puts "Default License Manager Project is: #{project.name} (ID: #{project.id})".colorize(:green)
    #    end
    #  end
    #
    #  desc "Conver Project with id PROJECT_ID= to a License Manager Project"
    #  task :convert_to_license_manager_project => :environment do
    #    project = ::Project.find ENV['PROJECT_ID']
    #    RLM::Setup::Projects.convert_to_license_manager_project!(project)
    #
    #    puts "Converting #{project.name}..."
    #
    #    status = RLM::Setup::Projects.check_license_manager_project_integrity(project)
    #
    #    status.each do |key, value|
    #      puts " #{value == true ? '+' : '-'} #{key}".colorize(value == true ? :green : :red)
    #    end
    #
    #  end
    #
    #end


  end

  namespace :invoicing do

    task :licenses => :environment do
      invoicing = LicenseInvoicingService.new(Issue.all)
      invoicing.invoice_licenses

      if invoicing.result.any?
        puts "SUCCESS:"
        puts invoicing.result.join("\n")
      end

      if invoicing.errors.any?
        puts "ERRORS:"
        puts invoicing.errors.join("\n")
      end

    end

  end

  task :sync_lef => :environment do
    LefService.sync_lefs_for_qlik
  end

  desc "Set all license issues from USER_ID to currently set default user id"
  task :reassign_license_user => :environment do
    default_id = Setting.plugin_redmine_license_manager['rlm_default_user_id']
    default_user = User.find_by(id: default_id)
    raise "No License user set" if default_user.nil?

    user = User.find_by(id: ENV['USER_ID'])
    raise "user with ID #{ENV['USER_ID']} not found" if user.nil?

    license_issues = Issue.where(
      tracker_id: RLM::Setup::Trackers.all.map(&:id),
      assigned_to_id: user.id
    )

    license_issues.update_all(assigned_to_id: default_user.id)
  end

end