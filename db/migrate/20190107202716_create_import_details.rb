class CreateImportDetails < ActiveRecord::Migration[5.2]
  def change
    create_table :import_details do |t|

      t.timestamps
    end
  end
end
