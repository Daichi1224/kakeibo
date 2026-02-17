class DashboardController < ApplicationController
  http_basic_authenticate_with(
    name: ENV.fetch("DASHBOARD_USER", "admin"),
    password: ENV.fetch("DASHBOARD_PASSWORD", "password")
  )

  def index
    @year = params[:year]&.to_i || Date.today.year
    @month = params[:month]&.to_i || Date.today.month

    @expenses = Expense.for_month(@year, @month)
    @total = @expenses.sum(:amount)
    @category_totals = @expenses.group(:category).sum(:amount)
    @daily_totals = @expenses.group(:date).sum(:amount)
    @recent_expenses = @expenses.recent.limit(10)
  end

  def expenses
    @year = params[:year]&.to_i || Date.today.year
    @month = params[:month]&.to_i || Date.today.month

    @expenses = Expense.for_month(@year, @month).recent
  end

  def reports
    @reports = MonthlyReport.order(year: :desc, month: :desc)
  end

  def report_detail
    @report = MonthlyReport.find(params[:id])
  end
end
