class AddImportColumns < ActiveRecord::Migration[5.2]
  def change
    add_column :imports, :name, :string
    add_column :imports, :initial_latitude, :float
    add_column :imports, :final_latitude, :float
    add_column :imports, :initial_longitude, :float
    add_column :imports, :final_longitude, :float
    add_column :imports, :language, :string
  end
end
