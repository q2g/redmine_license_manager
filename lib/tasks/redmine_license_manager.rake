namespace :rlm do
  namespace :setup do

    desc "Check if all required Components (Trackers, IssueStatuses, Activities, IssueCustomFields...) are set up"
    task :status => :environment do
      RLM::Setup.yaml_config['modules']['setup'].each do |component_name, settings|

        component_class = settings['class_name'].constantize
        setup_module    = "RLM::Setup::#{component_name.camelize}".constantize

        puts "Checking #{settings['class_name']}".colorize(:white).colorize(:background => :light_blue)

        settings['entries'].each do |entry_name|
          internal_name = RLM::Setup.name_for(entry_name, current_module_scope: setup_module.rlm_module_name_for_config)

          entry = component_class.find_by(setup_module.default_data_attributes(entry_name))

          output = [".. #{internal_name}"]

          if entry.nil?
            output << "[MISSING]".colorize(:red)
          else
            output << "[EXISTS]".colorize(:green)
          end

          puts output.join(" ")

          #checking attributes
          if entry.present?
            warn = "   [WARN]".colorize(:yellow).on_black
            setup_module.combined_data_attributes(entry_name).each do |key, value|
              if entry[key] != value
                puts "#{warn}: attribute '#{key.bold}' is #{entry[key].inspect.bold} - should be #{value.inspect.bold}"
              end
            end
          end

        end

        puts "---------------------\n"
      end

    end

    namespace :projects do

      desc "Creates a default license manager project if it is missing"
      task :create_default => :environment do
        if RLM::Setup::Projects.license_manager_projects.any?
          project = RLM::Setup::Projects.default_license_manager_project
          puts "Default License Manager Project is: #{project.name} (ID: #{project.id})".colorize(:yellow)
          puts ".. checking integrity"

          status = RLM::Setup::Projects.check_license_manager_project_integrity(project)
          if status == true
            puts ".. STATUS OK".colorize(:green)
          else
            puts ".. STATUS NOT OK".colorize(:red)
            puts "=> Please run 'rake rlm:setup:projects:convert_to_license_manager_project PROJECT_ID=#{project.id}' to setup data!"
          end
        else
          puts "Creating default Default License Manager Project"
          project = RLM::Setup::Projects.default_license_manager_project
          puts "Default License Manager Project is: #{project.name} (ID: #{project.id})".colorize(:green)
        end
      end

      desc "Conver Project with id PROJECT_ID= to a License Manager Project"
      task :convert_to_license_manager_project => :environment do
        project = ::Project.find ENV['PROJECT_ID']
        RLM::Setup::Projects.convert_to_license_manager_project!(project)

        puts "Converting #{project.name}..."

        status = RLM::Setup::Projects.check_license_manager_project_integrity(project)

        status.each do |key, value|
          puts " #{value == true ? '+' : '-'} #{key}".colorize(value == true ? :green : :red)
        end

      end

    end


  end
end