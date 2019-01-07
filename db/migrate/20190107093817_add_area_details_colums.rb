class AddAreaDetailsColums < ActiveRecord::Migration[5.2]
  def change
    add_reference :area_details, :areas
    add_column :area_details, :name, :string
    add_column :area_details, :state, :string
    add_column :area_details, :country, :string
    add_column :area_details, :language, :string
  end
end
