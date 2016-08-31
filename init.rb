Redmine::Plugin.register :redmine_license_manager do
  name 'Redmine License Manager'
  author 'Florian Eck for akquinet'
  description 'License Manager'
  version '0.1.0'

  Redmine::AccessControl.map do |map|
    map.project_module :redmine_license_manager do |pmap|
      pmap.permission :edit_licenses, { }
    end
  end
end

