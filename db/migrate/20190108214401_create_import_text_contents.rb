class CreateImportTextContents < ActiveRecord::Migration[5.2]
  def change
    create_table :import_text_contents do |t|

      t.timestamps
    end
  end
end
