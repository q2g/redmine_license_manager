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

  end
end