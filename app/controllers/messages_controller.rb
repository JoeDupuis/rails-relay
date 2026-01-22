class MessagesController < ApplicationController
  before_action :set_target

  def index
    messages = @channel.messages
                       .where("id < ?", params[:before_id])
                       .order(created_at: :desc)
                       .limit(50)
                       .reverse

    render partial: "messages/history", locals: {
      messages: messages,
      has_more: messages.size == 50,
      oldest_id: messages.first&.id
    }
  end

  def create
    if params[:message] && params[:message][:file].present?
      handle_file_upload
      return
    end

    content = params[:content]

    case content
    when /\A\/me (.+)/
      send_irc_action(@channel || params[:target], $1)
    when /\A\/msg (\S+) (.+)/
      send_pm($1, $2)
    when /\A\/notice (\S+) (.+)/
      send_notice($1, $2)
    when /\A\/nick (\S+)/
      change_nick($1)
    when /\A\/topic (.+)/
      set_topic($1)
    when /\A\/part/
      part_channel
      return
    when /\A\//
      flash[:alert] = "Unknown command"
      redirect_back fallback_location: @channel || @server
      return
    else
      send_message(@channel || params[:target], content)
    end

    return if performed?

    head :ok
  end

  private

  def set_target
    if params[:channel_id]
      @channel = Channel.joins(:server).where(servers: { user_id: Current.user.id }).find(params[:channel_id])
      @server = @channel.server
    else
      @server = Current.user.servers.find(params[:server_id])
    end
  end

  def send_message(target, content)
    target_name = target.is_a?(Channel) ? target.name : target

    return unless send_irc_command("privmsg", target: target_name, message: content)

    ActiveRecord::Base.transaction do
      @message = Message.create!(
        server: @server,
        channel: target.is_a?(Channel) ? target : nil,
        target: target.is_a?(Channel) ? nil : target,
        sender: @server.nickname,
        content: content,
        message_type: "privmsg"
      )
      @channel&.update!(last_read_message_id: @message.id)
    end
  end

  def send_irc_action(target, action_text)
    target_name = target.is_a?(Channel) ? target.name : target

    return unless send_irc_command("action", target: target_name, message: action_text)

    ActiveRecord::Base.transaction do
      @message = Message.create!(
        server: @server,
        channel: target.is_a?(Channel) ? target : nil,
        target: target.is_a?(Channel) ? nil : target,
        sender: @server.nickname,
        content: action_text,
        message_type: "action"
      )
      @channel&.update!(last_read_message_id: @message.id)
    end
  end

  def send_pm(nick, content)
    return unless send_irc_command("privmsg", target: nick, message: content)

    conversation = Conversation.find_or_create_by!(server: @server, target_nick: nick)
    conversation.touch(:last_message_at)

    @message = Message.create!(
      server: @server,
      channel: nil,
      target: nick,
      sender: @server.nickname,
      content: content,
      message_type: "privmsg"
    )

    @created_conversation = conversation
  end

  def send_notice(target, content)
    send_irc_command("notice", target: target, message: content)
  end

  def change_nick(new_nick)
    send_irc_command("nick", nickname: new_nick)
  end

  def set_topic(topic)
    return unless @channel
    send_irc_command("topic", channel: @channel.name, topic: topic)
  end

  def part_channel
    return redirect_to(@server) unless @channel
    InternalApiClient.send_command(
      server_id: @server.id,
      command: "part",
      params: { channel: @channel.name }
    )
    redirect_to @server
  rescue InternalApiClient::ConnectionNotFound
    @server.mark_disconnected!
    flash[:alert] = "Connection lost"
    redirect_to @server
  rescue InternalApiClient::ServiceUnavailable
    flash[:alert] = "IRC service unavailable"
    redirect_to @server
  end

  def send_irc_command(command, **params)
    InternalApiClient.send_command(
      server_id: @server.id,
      command: command,
      params: params
    )
    true
  rescue InternalApiClient::ConnectionNotFound
    @server.mark_disconnected!
    flash[:alert] = "Connection lost"
    redirect_to @server
    false
  rescue InternalApiClient::ServiceUnavailable
    flash[:alert] = "IRC service unavailable"
    redirect_back fallback_location: @channel || @server
    false
  end

  def handle_file_upload
    @message = Message.new(
      server: @server,
      channel: @channel,
      sender: @server.nickname,
      message_type: "privmsg",
      file: params[:message][:file]
    )

    saved = ActiveRecord::Base.transaction do
      if @message.save
        @channel&.update!(last_read_message_id: @message.id)
        true
      else
        false
      end
    end

    if saved
      head :ok
    else
      flash[:alert] = @message.errors.full_messages.join(", ")
      redirect_back fallback_location: @channel || @server
    end
  end
end
