Redmine::Plugin.register :redmine_license_manager do
  name 'Redmine License Manager'
  author 'Florian Eck for akquinet'
  description 'License Manager'
  version '0.1.0'

  menu :top_menu, :license_manager, { :controller => 'license_manager', :action => 'index' }, :caption => :license_manager, if: Proc.new { User.current.logged? && User.current.allowed_to_globally?(:edit_licenses) }, :html => {:class => 'icon icon-time'}

  Redmine::AccessControl.map do |map|
    map.project_module :license_manager do |pmap|
      pmap.permission :edit_licenses, #{ user_deputies: [:index, :move_up, :move_down, :create, :delete, :set_availabilities] }, global: true
    end
  end
end

require "redmine_license_manager"

#Rails.application.config.after_initialize do
#  User.send(:include, RedmineAutoDeputy::UserAvailabilityExtension)
#  User.send(:include, RedmineAutoDeputy::UserDeputyExtension)
#  Issue.send(:include, RedmineAutoDeputy::IssueExtension)
#  Project.send(:include, RedmineAutoDeputy::ProjectExtension)
#end