class CreateImportPhotos < ActiveRecord::Migration[5.2]
  def change
    create_table :import_photos do |t|

      t.timestamps
    end
  end
end
