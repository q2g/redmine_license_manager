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
      issues = Issue.where('(tracker_id = 6 or tracker_id = 9) and (status_id = 8 or status_id = 9) and  start_date <= ?', DateTime.now)
      LicenseInvoicingService.new(issues).invoice_licenses
    end
    
  end
  
end