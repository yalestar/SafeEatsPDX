class AddToInspections < ActiveRecord::Migration
  def self.up
    add_column :inspections, :violations, :text
    add_column :inspections, :type, :string
    add_column :inspections, :internal_id, :string
  end

  def self.down
    remove_column :inspections, :internal_id
    remove_column :inspections, :type
    remove_column :inspections, :violations
  end
end