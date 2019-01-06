class CreateAreaDetails < ActiveRecord::Migration[5.2]
  def change
    create_table :area_details do |t|

      t.timestamps
    end
  end
end
