class CreatePointDetails < ActiveRecord::Migration[5.2]
  def change
    create_table :point_details do |t|

      t.timestamps
    end
  end
end
