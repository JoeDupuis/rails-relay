class IrcEventHandler
  def self.handle(server, event)
    new(server, event).handle
  end

  def initialize(server, event)
    @server = server
    @event = normalize_event(event)
  end

  def normalize_event(event)
    case event
    when ActionController::Parameters
      event.permit!.to_h.with_indifferent_access
    when Hash
      event.with_indifferent_access
    else
      event.to_h.with_indifferent_access
    end
  end

  def handle
    case @event[:type]
    when "connected"
      handle_connected
    when "disconnected"
      handle_disconnected
    when "message"
      handle_message
    when "action"
      handle_action
    when "notice"
      handle_notice
    when "join"
      handle_join
    when "part"
      handle_part
    when "quit"
      handle_quit
    when "kick"
      handle_kick
    when "nick"
      handle_nick
    when "topic"
      handle_topic
    when "names"
      handle_names
    when "no_such_nick"
      handle_no_such_nick
    end
  end

  private

  def data
    @event[:data]
  end

  def source_nick
    data[:source]&.split("!")&.first || data[:source]
  end

  def handle_connected
    @server.update!(connected_at: Time.current)
    auto_join_channels
  end

  def auto_join_channels
    @server.channels.where(auto_join: true).find_each do |channel|
      InternalApiClient.send_command(
        server_id: @server.id,
        command: "join",
        params: { channel: channel.name }
      )
    rescue InternalApiClient::ServiceUnavailable, InternalApiClient::ConnectionNotFound => e
      Rails.logger.error "Auto-join failed for #{channel.name}: #{e.message}"
    end
  end

  def handle_disconnected
    @server.mark_disconnected!
  end

  def handle_message
    target = data[:target]

    if channel_target?(target)
      channel = Channel.find_or_create_by!(server: @server, name: target)
      message = Message.create!(
        server: @server,
        channel: channel,
        sender: source_nick,
        content: data[:text],
        message_type: "privmsg"
      )

      check_highlight(message)
    else
      conversation = Conversation.find_or_initialize_by(
        server: @server,
        target_nick: source_nick
      )
      was_closed = conversation.persisted? && conversation.closed?
      conversation.reopen! if was_closed
      conversation.save! if conversation.new_record?
      conversation.update!(last_message_at: Time.current, online: true)
      conversation.broadcast_sidebar_add if was_closed

      message = Message.create!(
        server: @server,
        channel: nil,
        target: source_nick,
        sender: source_nick,
        content: data[:text],
        message_type: "privmsg"
      )

      notification = Notification.create!(message: message, reason: "dm")
      broadcast_notification(notification)
    end
  end

  def handle_action
    target = data[:target]
    channel = Channel.find_or_create_by!(server: @server, name: target) if channel_target?(target)

    message = Message.create!(
      server: @server,
      channel: channel,
      target: channel ? nil : source_nick,
      sender: source_nick,
      content: data[:text],
      message_type: "action"
    )

    check_highlight(message) if channel
  end

  def handle_notice
    target = data[:target]
    channel = Channel.find_by(server: @server, name: target) if channel_target?(target)

    Message.create!(
      server: @server,
      channel: channel,
      target: channel ? nil : source_nick,
      sender: source_nick,
      content: data[:text],
      message_type: "notice"
    )
  end

  def handle_join
    channel = Channel.find_or_create_by!(server: @server, name: data[:target])

    if source_nick == @server.nickname
      channel.update!(joined: true)
    else
      channel.channel_users.find_or_create_by!(nickname: source_nick)
    end

    Message.create!(
      server: @server,
      channel: channel,
      sender: source_nick,
      message_type: "join"
    )
  end

  def handle_part
    channel = Channel.find_by(server: @server, name: data[:target])
    return unless channel

    if source_nick == @server.nickname
      channel.update!(joined: false)
      channel.channel_users.destroy_all
    else
      channel.channel_users.find_by(nickname: source_nick)&.destroy
    end

    Message.create!(
      server: @server,
      channel: channel,
      sender: source_nick,
      content: data[:text],
      message_type: "part"
    )
  end

  def handle_quit
    @server.channels.each do |channel|
      channel.channel_users.find_by(nickname: source_nick)&.destroy
    end

    Message.create!(
      server: @server,
      sender: source_nick,
      content: data[:text],
      message_type: "quit"
    )
  end

  def handle_kick
    channel = Channel.find_by(server: @server, name: data[:target])
    return unless channel

    kicked_nick = data[:kicked]

    if kicked_nick.casecmp?(@server.nickname)
      channel.update!(joined: false)
      channel.channel_users.destroy_all
    else
      channel.channel_users.find_by(nickname: kicked_nick)&.destroy
    end

    reason_text = data[:text].present? ? " (#{data[:text]})" : ""
    Message.create!(
      server: @server,
      channel: channel,
      sender: kicked_nick,
      content: "was kicked by #{source_nick}#{reason_text}",
      message_type: "kick"
    )
  end

  def handle_nick
    old_nick = source_nick
    new_nick = data[:new_nick]

    if old_nick.casecmp?(@server.nickname)
      @server.update!(nickname: new_nick)
    end

    @server.channels.each do |channel|
      user = channel.channel_users.find_by(nickname: old_nick)
      user&.update!(nickname: new_nick)
    end

    Message.create!(
      server: @server,
      sender: old_nick,
      content: new_nick,
      message_type: "nick"
    )
  end

  def handle_topic
    channel = Channel.find_by(server: @server, name: data[:target])
    return unless channel

    channel.update!(topic: data[:text])

    Message.create!(
      server: @server,
      channel: channel,
      sender: source_nick,
      content: data[:text],
      message_type: "topic"
    )
  end

  def handle_names
    channel = Channel.find_by(server: @server, name: data[:channel])
    return unless channel

    ChannelUser.without_broadcasts do
      channel.channel_users.destroy_all
      data[:names].each do |name|
        modes = ""
        nick = name

        if name.start_with?("@")
          modes = "o"
          nick = name[1..]
        elsif name.start_with?("+")
          modes = "v"
          nick = name[1..]
        end

        channel.channel_users.create!(nickname: nick, modes: modes)
      end
    end

    channel.reload.broadcast_user_list
  end

  def handle_no_such_nick
    nick = data[:nick]
    return unless nick

    conversation = Conversation.find_by(server: @server, target_nick: nick)
    return unless conversation&.online?

    conversation.update!(online: false)
    conversation.broadcast_presence_update
  end

  def channel_target?(target)
    target&.start_with?("#", "&")
  end

  def check_highlight(message)
    return if message.sender.casecmp?(@server.nickname)
    if message.content.match?(/\b#{Regexp.escape(@server.nickname)}\b/i)
      notification = Notification.create!(message: message, reason: "highlight")
      broadcast_notification(notification)
    end
  end

  def broadcast_notification(notification)
    ActionCable.server.broadcast(
      "user_#{@server.user.id}_notifications",
      {
        type: "notification",
        id: notification.id,
        reason: notification.reason,
        sender: notification.message.sender,
        preview: notification.message.content.truncate(100),
        channel: notification.message.channel&.name
      }
    )
  end
end
