class ExpenseParserService
  CATEGORIES = Expense::CATEGORIES

  CATEGORY_KEYWORDS = {
    "外食" => %w[外食 ランチ レストラン ラーメン 寿司 すし 居酒屋 焼肉 うどん そば ピザ マック スタバ カフェ コーヒー 定食 牛丼 回転寿司 ファミレス パスタ 昼食 夕食 朝食 弁当 コンビニ 食事 飲み おやつ お菓子 ごはん ご飯 パン],
    "自炊" => %w[自炊 スーパー 食材 野菜 肉 魚 米 調味料 材料],
    "交通費" => %w[電車 バス タクシー 地下鉄 定期 Suica suica PASMO pasmo 交通 駐車 ガソリン 高速],
    "娯楽" => %w[映画 ゲーム 本 書籍 漫画 Netflix netflix 音楽 ライブ カラオケ 旅行 ホテル],
    "日用品" => %w[洗剤 シャンプー ティッシュ トイレットペーパー 歯ブラシ 100均 ドラッグストア 掃除],
    "衣服" => %w[服 シャツ パンツ 靴 スニーカー ユニクロ ZARA GU gu],
    "医療" => %w[病院 薬 歯医者 クリニック 診察 処方],
    "通信" => %w[スマホ 携帯 Wi-Fi wifi プロバイダ 通信],
    "住居" => %w[家賃],
    "教育" => %w[本 参考書 セミナー 講座 スクール 塾],
    "光熱費" => %w[電気 ガス 水道 光熱],
    "投資" => %w[投資 株 積立 NISA nisa iDeCo ideco 投信 ETF etf],
  }.freeze

  def self.parse(text)
    new.parse(text)
  end

  def parse(text)
    amount = extract_amount(text)
    return { error: "金額が読み取れませんでした。「ランチ850円」のように入力してください。" } unless amount

    date = extract_date(text)
    description = extract_description(text, amount)
    category = guess_category(text)

    {
      date: date,
      amount: amount,
      category: category,
      description: description
    }
  end

  private

  def extract_amount(text)
    # Match patterns like: 1500円, 1,500円, ¥1500, 1500
    if text =~ /[¥￥]?\s*([\d,]+)\s*円/
      $1.delete(",").to_i
    elsif text =~ /[¥￥]([\d,]+)/
      $1.delete(",").to_i
    elsif text =~ /([\d,]{3,})/
      # 3桁以上の数字を金額とみなす
      $1.delete(",").to_i
    end
  end

  def extract_date(text)
    today = Date.today

    case text
    when /昨日/
      today - 1
    when /一昨日|おととい/
      today - 2
    when /(\d{1,2})\s*[\/月]\s*(\d{1,2})/
      month = $1.to_i
      day = $2.to_i
      year = month > today.month ? today.year - 1 : today.year
      Date.new(year, month, day) rescue today
    else
      today
    end
  end

  def extract_description(text, amount)
    # 金額部分と日付表現を除去して残りを説明にする
    desc = text.dup
    desc.gsub!(/[¥￥]?\s*[\d,]+\s*円?/, "")
    desc.gsub!(/今日|昨日|一昨日|おととい/, "")
    desc.gsub!(/\d{1,2}\s*[\/月]\s*\d{1,2}/, "")
    desc.strip!
    desc.empty? ? "支出" : desc
  end

  def guess_category(text)
    CATEGORY_KEYWORDS.each do |category, keywords|
      return category if keywords.any? { |kw| text.include?(kw) }
    end
    "その他"
  end
end
