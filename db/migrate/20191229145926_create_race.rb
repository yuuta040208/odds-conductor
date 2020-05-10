class CreateRace < ActiveRecord::Migration[6.0]
  def change
    create_table :races do |t|
      t.integer :time
      t.string :date
      t.string :place
      t.integer :day
      t.integer :number
      t.string :name
      t.text :url

      t.timestamps
    end
  end
end
