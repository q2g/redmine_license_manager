class CreateRlmLefAccessLogs < ActiveRecord::Migration

  def change
    create_table :rlm_lef_access_logs do |t|
      t.string :ip
      t.string :status
      t.text   :request_params 
      t.timestamps
    end
  end

end