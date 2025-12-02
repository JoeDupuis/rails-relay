module MessagesHelper
  def format_message(message)
    case message.message_type
    when "join"
      "#{message.sender} joined"
    when "part"
      "#{message.sender} left" + (message.content.present? ? " (#{message.content})" : "")
    when "quit"
      "#{message.sender} quit" + (message.content.present? ? " (#{message.content})" : "")
    when "kick"
      "#{message.sender} #{message.content}"
    when "topic"
      "#{message.sender} changed topic to: #{message.content}"
    when "nick"
      "#{message.sender} is now known as #{message.content}"
    else
      message.content
    end
  end

  def current_nickname
    @channel&.server&.nickname
  end
end
