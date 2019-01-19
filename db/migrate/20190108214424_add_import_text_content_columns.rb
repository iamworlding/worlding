class AddImportTextContentColumns < ActiveRecord::Migration[5.2]
  def change
    add_column :import_text_contents, :import_point_id, :integer
    add_column :import_text_contents, :title, :string
    add_column :import_text_contents, :content, :string

    add_foreign_key :import_text_contents, :import_points
  end
end
