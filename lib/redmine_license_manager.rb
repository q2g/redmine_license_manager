module RLM; end

require File.expand_path("../../lib/rlm/setup.rb", __FILE__)
require File.expand_path("../../lib/rlm/issue_extension.rb", __FILE__)

require File.expand_path("../../app/services/lef_service.rb", __FILE__)

Rails.application.config.after_initialize do
  Issue.send(:include, RLM::IssueExtension)
  TimeEntry.send(:include, RLM::TimeEntryExtension)
end  
