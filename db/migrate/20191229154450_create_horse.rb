class CreateHorse < ActiveRecord::Migration[6.0]
  def change
    create_table :horses do |t|
      t.references :race, foreign_key: true
      t.integer :number
      t.string :name
      t.string :win
      t.float :place

      t.timestamps
    end
  end
end
