class MonthlyReportService
  def self.generate(year, month)
    new(year, month).generate
  end

  def initialize(year, month)
    @year = year
    @month = month
  end

  def generate
    expenses = Expense.for_month(@year, @month)
    return nil if expenses.empty?

    total = expenses.sum(:amount)
    category_totals = expenses.group(:category).sum(:amount).sort_by { |_, v| -v }

    # Previous month comparison
    prev_date = Date.new(@year, @month, 1).prev_month
    prev_expenses = Expense.for_month(prev_date.year, prev_date.month)
    prev_total = prev_expenses.sum(:amount)

    report_text = build_report(expenses, total, category_totals, prev_total)

    report = MonthlyReport.find_or_initialize_by(year: @year, month: @month)
    report.update!(total_amount: total, report_text: report_text)
    report
  end

  private

  def build_report(expenses, total, category_totals, prev_total)
    lines = []
    lines << "【#{@year}年#{@month}月 支出レポート】"
    lines << ""
    lines << "合計: #{format_amount(total)}円（#{expenses.count}件）"

    if prev_total > 0
      diff = total - prev_total
      sign = diff >= 0 ? "+" : ""
      lines << "前月比: #{sign}#{format_amount(diff)}円"
    end

    lines << ""
    lines << "--- カテゴリ別 ---"
    category_totals.each do |cat, amt|
      pct = (amt.to_f / total * 100).round(1)
      lines << "#{cat}: #{format_amount(amt)}円 (#{pct}%)"
    end

    # Top spending day
    daily = expenses.group(:date).sum(:amount).max_by { |_, v| v }
    if daily
      lines << ""
      lines << "最も支出が多かった日: #{daily[0].strftime('%m/%d')} #{format_amount(daily[1])}円"
    end

    lines.join("\n")
  end

  def format_amount(amount)
    amount.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse
  end
end
