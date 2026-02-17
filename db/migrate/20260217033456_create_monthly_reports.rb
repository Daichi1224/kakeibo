class CreateMonthlyReports < ActiveRecord::Migration[7.2]
  def change
    create_table :monthly_reports do |t|
      t.integer :year
      t.integer :month
      t.integer :total_amount
      t.text :report_text

      t.timestamps
    end
  end
end
