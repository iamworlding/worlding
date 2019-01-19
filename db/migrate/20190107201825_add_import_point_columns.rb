class AddImportPointColumns < ActiveRecord::Migration[5.2]
  def change
    add_column :import_points, :import_id, :integer
    add_column :import_points, :wikipedia_id, :string
    add_column :import_points, :wikibase_id, :string
    add_column :import_points, :title, :string
    add_column :import_points, :latitude, :float
    add_column :import_points, :longitude, :float

    add_foreign_key :import_points, :imports
  end
end
