class AddImportPhotoColumns < ActiveRecord::Migration[5.2]
  def change
    add_reference :import_photos, :import_points
    add_column :import_photos, :file_url, :string
  end
end
