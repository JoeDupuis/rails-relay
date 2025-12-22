module MessagesHelper
  URL_REGEX = %r{(https?://[^\s<>\[\]]+)}i

  def format_message(message)
    content = case message.message_type
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

    linkify(content)
  end

  def current_nickname
    @channel&.server&.nickname
  end

  private

  def linkify(text)
    return text if text.blank?

    escaped = ERB::Util.html_escape(text)
    linked = escaped.gsub(URL_REGEX) do |url|
      %(<a href="#{url}" target="_blank" rel="noopener noreferrer">#{url}</a>)
    end
    linked.html_safe
  end
end
