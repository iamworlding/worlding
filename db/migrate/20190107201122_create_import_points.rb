class CreateImportPoints < ActiveRecord::Migration[5.2]
  def change
    create_table :import_points do |t|

      t.timestamps
    end
  end
end
