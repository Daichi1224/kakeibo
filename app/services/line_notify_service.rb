class LineNotifyService
  def self.send_report(report)
    client = Line::Bot::V2::MessagingApi::ApiClient.new(
      channel_access_token: ENV["LINE_CHANNEL_TOKEN"]
    )

    text = "#{report.year}年#{report.month}月のレポート\n" \
           "合計: #{format_amount(report.total_amount)}円\n\n" \
           "#{report.report_text}"

    message = Line::Bot::V2::MessagingApi::TextMessage.new(text: truncate_for_line(text))
    request = Line::Bot::V2::MessagingApi::BroadcastRequest.new(messages: [message])
    client.broadcast(broadcast_request: request)
  end

  def self.format_amount(amount)
    amount.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse
  end

  def self.truncate_for_line(text)
    text.length > 4900 ? text[0..4896] + "..." : text
  end
end
