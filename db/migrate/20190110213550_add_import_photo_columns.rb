class AddImportPhotoColumns < ActiveRecord::Migration[5.2]
  def change
    add_column :import_photos, :import_point_id, :integer
    add_column :import_photos, :file_url, :string

    add_foreign_key :import_photos, :import_points
  end
end
