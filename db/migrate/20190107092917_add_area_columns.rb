class AddAreaColumns < ActiveRecord::Migration[5.2]
  def change
    add_column :areas, :initial_latitude, :float
    add_column :areas, :final_latitude, :float
    add_column :areas, :initial_longitude, :float
    add_column :areas, :final_longitude, :float
    add_column :areas, :es, :boolean, :default => false
    add_column :areas, :en, :boolean, :default => false
  end
end
