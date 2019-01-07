class AddAreaColumns < ActiveRecord::Migration[5.2]
  def change
    add_column :areas, :max_latitude, :float
    add_column :areas, :min_latitude, :float
    add_column :areas, :max_longitude, :float
    add_column :areas, :min_longitude, :float
    add_column :areas, :max_length, :integer
    add_column :areas, :max_five_stars, :float
    add_column :areas, :max_four_stars, :float
    add_column :areas, :max_three_stars, :float
    add_column :areas, :max_two_stars, :float
    add_column :areas, :max_one_stars, :float
    add_column :areas, :es, :boolean, :default => false
    add_column :areas, :en, :boolean, :default => false
  end
end
