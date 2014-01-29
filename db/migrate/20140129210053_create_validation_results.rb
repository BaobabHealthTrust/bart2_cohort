class CreateValidationResults < ActiveRecord::Migration
  def self.up
    create_table :validation_results do |t|
      t.integer :rule_id
      t.integer :failures
      
      t.timestamps
    end
  end

  def self.down
    drop_table :validation_results
  end
end
