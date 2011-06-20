class CreateInspections < ActiveRecord::Migration
  def self.up
    create_table :inspections do |t|
      t.integer :restaurant_id
      t.date :inspection_date
      t.integer :score
      t.string :url
      t.text :notes
      
      t.timestamps
    end
  end

  def self.down
    drop_table :inspections
  end
end
