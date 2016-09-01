class AddRlmInternalNameToIssueStatus < ActiveRecord::Migration

  def change
    add_column :issue_statuses, :rlm_internal_name, :string
  end

end