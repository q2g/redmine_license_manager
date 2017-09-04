class AddInternalNameToIssueStatus < ActiveRecord::Migration

  def change
    add_column :issue_statuses, :internal_name, :string unless column_exists?(:issue_statuses, :internal_name)
  end

end