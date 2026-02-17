class MonthlyReport < ApplicationRecord
  validates :year, presence: true
  validates :month, presence: true, inclusion: { in: 1..12 }
  validates :year, uniqueness: { scope: :month }

  def expenses
    Expense.for_month(year, month)
  end
end
