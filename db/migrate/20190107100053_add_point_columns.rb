class AddPointColumns < ActiveRecord::Migration[5.2]
  def change
    add_reference :points, :areas
    add_column :points, :latitude, :float
    add_column :points, :longitude, :float
    add_column :points, :likes, :integer
    add_column :points, :es, :boolean
    add_column :points, :en, :boolean
  end
end
