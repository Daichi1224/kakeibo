class WebhookController < ApplicationController
  skip_before_action :verify_authenticity_token

  def create
    body = request.body.read
    signature = request.env["HTTP_X_LINE_SIGNATURE"]

    parser = Line::Bot::V2::WebhookParser.new(channel_secret: ENV["LINE_CHANNEL_SECRET"])

    begin
      events = parser.parse(body: body, signature: signature)
    rescue Line::Bot::V2::WebhookParser::InvalidSignatureError
      head :bad_request
      return
    end

    events.each do |event|
      case event
      when Line::Bot::V2::Webhook::MessageEvent
        handle_message(event)
      end
    end

    head :ok
  end

  private

  def client
    @client ||= Line::Bot::V2::MessagingApi::ApiClient.new(
      channel_access_token: ENV["LINE_CHANNEL_TOKEN"]
    )
  end

  def handle_message(event)
    message = event.message

    case message
    when Line::Bot::V2::Webhook::TextMessageContent
      handle_text(event, message.text)
    else
      reply_text(event, "テキストで「ランチ850円」のように送ってください。")
    end
  end

  def handle_text(event, text)
    # 直前の1件削除: 「取り消し」「間違えた」（先にチェック）
    if text =~ /\A(取り消し|間違えた|undo)\z/i
      handle_undo(event)
      return
    end

    # カテゴリ修正: カテゴリ名だけ送られた場合、直前の登録を修正
    if Expense::CATEGORIES.include?(text.strip)
      handle_category_fix(event, text.strip)
      return
    end

    # 削除コマンド: 「2/17削除」「2月17日のデータ削除」「今日のデータ消して」など
    if text =~ /削除|消して|取り消/
      handle_delete(event, text)
      return
    end

    result = ExpenseParserService.parse(text)

    if result[:error]
      reply_text(event, result[:error])
      return
    end

    expense = Expense.new(result.merge(original_text: text))

    if expense.save
      reply_text(event, format_confirmation(expense))
    else
      reply_text(event, "登録に失敗しました: #{expense.errors.full_messages.join(', ')}")
    end
  end

  def handle_category_fix(event, category)
    last_expense = Expense.order(created_at: :desc).first

    if last_expense
      old_category = last_expense.category
      last_expense.update!(category: category)
      amount_str = last_expense.amount.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse
      reply_text(event, "#{last_expense.description} #{amount_str}円 のカテゴリを「#{old_category}」→「#{category}」に修正しました")
    else
      reply_text(event, "修正するデータがありません。")
    end
  end

  def handle_delete(event, text)
    # 月単位: 「2月のデータ削除」「2月全て消して」
    if text =~ /(\d{1,2})月.*(?:削除|消して|取り消)/
      month = $1.to_i
      if text !~ /\d{1,2}日/
        today = Date.today
        year = month > today.month ? today.year - 1 : today.year
        expenses = Expense.for_month(year, month)
      count = expenses.count

      if count == 0
        reply_text(event, "#{month}月のデータはありません。")
      else
        expenses.destroy_all
        reply_text(event, "#{month}月のデータ #{count}件 を全て削除しました。")
      end
      return
      end
    end

    # 日単位
    date = parse_date_from_text(text)

    unless date
      reply_text(event, "日付が読み取れませんでした。「2/17削除」「2月のデータ削除」のように送ってください。")
      return
    end

    expenses = Expense.where(date: date)
    count = expenses.count

    if count == 0
      reply_text(event, "#{date.strftime('%m/%d')} のデータはありません。")
    else
      expenses.destroy_all
      reply_text(event, "#{date.strftime('%m/%d')} のデータ #{count}件 を削除しました。")
    end
  end

  def handle_undo(event)
    last_expense = Expense.order(created_at: :desc).first

    if last_expense
      desc = "#{last_expense.date.strftime('%m/%d')} #{last_expense.category} #{last_expense.description} #{last_expense.amount}円"
      last_expense.destroy
      reply_text(event, "#{desc} を取り消しました。")
    else
      reply_text(event, "取り消すデータがありません。")
    end
  end

  def parse_date_from_text(text)
    today = Date.today

    case text
    when /今日/
      today
    when /昨日/
      today - 1
    when /(\d{1,2})\s*[\/月]\s*(\d{1,2})/
      month = $1.to_i
      day = $2.to_i
      year = month > today.month ? today.year - 1 : today.year
      Date.new(year, month, day) rescue nil
    end
  end

  def reply_text(event, text)
    message = Line::Bot::V2::MessagingApi::TextMessage.new(text: text)
    request = Line::Bot::V2::MessagingApi::ReplyMessageRequest.new(
      reply_token: event.reply_token,
      messages: [message]
    )
    client.reply_message(reply_message_request: request)
  end

  def format_confirmation(expense)
    amount_str = expense.amount.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse
    "#{expense.date.strftime('%m/%d')} [#{expense.category}] #{expense.description} #{amount_str}円 登録しました\n\nカテゴリが違う場合は正しいカテゴリ名を送ってください\n(#{Expense::CATEGORIES.join(' / ')})"
  end
end
