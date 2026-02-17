# Sample data for development
today = Date.today

expenses = [
  { date: today, amount: 850, category: "食費", description: "ランチ 定食" },
  { date: today - 1, amount: 1200, category: "食費", description: "夕食 ラーメン" },
  { date: today - 2, amount: 350, category: "交通費", description: "バス" },
  { date: today - 3, amount: 3500, category: "娯楽", description: "映画" },
  { date: today - 4, amount: 680, category: "日用品", description: "洗剤" },
  { date: today - 5, amount: 1500, category: "食費", description: "ランチ イタリアン" },
  { date: today - 6, amount: 280, category: "交通費", description: "電車" },
  { date: today - 7, amount: 2000, category: "衣服", description: "Tシャツ" },
  { date: today - 8, amount: 500, category: "食費", description: "コーヒー・パン" },
  { date: today - 9, amount: 1800, category: "通信", description: "モバイルSuica チャージ" },
]

expenses.each do |attrs|
  Expense.find_or_create_by!(attrs)
end

puts "Created #{expenses.size} sample expenses."
