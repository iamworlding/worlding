class AddPointDetailColumns < ActiveRecord::Migration[5.2]
  def change
    add_reference :point_details, :points
    add_column :point_details, :name, :string
    add_column :point_details, :local_name, :string
    add_column :point_details, :language, :string
  end
end
