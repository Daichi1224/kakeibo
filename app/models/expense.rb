class Expense < ApplicationRecord
  CATEGORIES = %w[外食 自炊 交通費 娯楽 日用品 衣服 医療 通信 住居 教育 光熱費 投資 その他].freeze
  FOOD_CATEGORIES = %w[外食 自炊].freeze

  validates :date, presence: true
  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :category, presence: true, inclusion: { in: CATEGORIES }

  scope :for_month, ->(year, month) {
    start_date = Date.new(year, month, 1)
    end_date = start_date.end_of_month
    where(date: start_date..end_date)
  }

  scope :recent, -> { order(date: :desc, created_at: :desc) }
end
