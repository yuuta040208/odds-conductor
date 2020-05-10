class CreateOdds < ActiveRecord::Migration[6.0]
  def change
    create_table :odds do |t|
      t.references :race, foreign_key: true
      t.integer :first_horse_number
      t.integer :second_horse_number
      t.float :quinella
      t.float :quinella_place
      t.float :exacta

      t.timestamps
    end
  end
end
