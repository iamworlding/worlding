class AddLengthColumnToImportContent < ActiveRecord::Migration[5.2]
  def change
    add_column :import_text_contents, :content_length, :integer
  end
end
