namespace :report do
  desc "Generate monthly report for the previous month and send via LINE"
  task generate: :environment do
    target = Date.today.prev_month
    year = target.year
    month = target.month

    puts "Generating report for #{year}/#{month}..."

    report = MonthlyReportService.generate(year, month)

    if report
      puts "Report generated. Total: #{report.total_amount}円"
      puts "Sending via LINE..."
      LineNotifyService.send_report(report)
      puts "Done!"
    else
      puts "No expenses found for #{year}/#{month}. Skipping."
    end
  end

  desc "Generate report for a specific month (e.g., rake report:for[2026,2])"
  task :for, [:year, :month] => :environment do |_, args|
    year = args[:year].to_i
    month = args[:month].to_i

    puts "Generating report for #{year}/#{month}..."

    report = MonthlyReportService.generate(year, month)

    if report
      puts "Report generated. Total: #{report.total_amount}円"
      puts report.report_text
    else
      puts "No expenses found for #{year}/#{month}."
    end
  end
end
