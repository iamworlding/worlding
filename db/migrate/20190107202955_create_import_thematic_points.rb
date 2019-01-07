class CreateImportThematicPoints < ActiveRecord::Migration[5.2]
  def change
    create_table :import_thematic_points do |t|

      t.timestamps
    end
  end
end
