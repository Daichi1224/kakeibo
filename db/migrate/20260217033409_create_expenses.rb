class CreateExpenses < ActiveRecord::Migration[7.2]
  def change
    create_table :expenses do |t|
      t.date :date
      t.integer :amount
      t.string :category
      t.string :description
      t.text :original_text

      t.timestamps
    end
  end
end
