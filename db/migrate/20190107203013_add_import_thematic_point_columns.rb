class AddImportThematicPointColumns < ActiveRecord::Migration[5.2]
  def change
    add_column :import_thematic_points, :import_point_id, :integer
    add_column :import_thematic_points, :wikibase_id, :string
    add_column :import_thematic_points, :name, :string

    add_foreign_key :import_thematic_points, :import_points
  end
end
