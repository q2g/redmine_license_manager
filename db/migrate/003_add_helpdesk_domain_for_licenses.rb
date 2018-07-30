class AddHelpdeskDomainForLicenses < ActiveRecord::Migration

  def change
    add_column :easy_helpdesk_projects, :mail_domain_for_licenses, :string
  end

end