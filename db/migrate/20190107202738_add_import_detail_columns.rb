class AddImportDetailColumns < ActiveRecord::Migration[5.2]
  def change
    add_reference :import_details, :import_points
    add_column :import_details, :type, :string
    add_column :import_details, :title, :string
    add_column :import_details, :content, :string
  end
end
