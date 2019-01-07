class AddOperationalLogColumns < ActiveRecord::Migration[5.2]
  def change
    add_column :operational_logs, :source, :string
    add_column :operational_logs, :event, :string
    add_column :operational_logs, :comment, :string
  end
end
