class AddImportTextContentColumns < ActiveRecord::Migration[5.2]
  def change
    add_reference :import_text_contents, :import_points
    add_column :import_text_contents, :title, :string
    add_column :import_text_contents, :content, :string
  end
end
