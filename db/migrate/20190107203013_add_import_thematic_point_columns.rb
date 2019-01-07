class AddImportThematicPointColumns < ActiveRecord::Migration[5.2]
  def change
    add_reference :import_thematic_points, :import_points
    add_column :import_thematic_points, :wikibase_id, :string
    add_column :import_thematic_points, :name, :string
  end
end
