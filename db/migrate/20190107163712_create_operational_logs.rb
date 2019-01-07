class CreateOperationalLogs < ActiveRecord::Migration[5.2]
  def change
    create_table :operational_logs do |t|

      t.timestamps
    end
  end
end
