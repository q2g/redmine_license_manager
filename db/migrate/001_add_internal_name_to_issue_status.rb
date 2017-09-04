class AddInternalNameToIssueStatus < ActiveRecord::Migration

  def change
    add_column :issue_statuses, :internal_name, :string
  end

end