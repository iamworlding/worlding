class CreateThematics < ActiveRecord::Migration[5.2]
  def change
    create_table :thematics do |t|

      t.timestamps
    end
  end
end
