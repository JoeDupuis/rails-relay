class MessagesController < ApplicationController
  before_action :set_target

  def create
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

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_back fallback_location: @channel || @server }
    end
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

    @message = Message.create!(
      server: @server,
      channel: target.is_a?(Channel) ? target : nil,
      target: target.is_a?(Channel) ? nil : target,
      sender: @server.nickname,
      content: content,
      message_type: "privmsg"
    )

    send_irc_command("privmsg", target: target_name, message: content)
  end

  def send_irc_action(target, action_text)
    target_name = target.is_a?(Channel) ? target.name : target

    @message = Message.create!(
      server: @server,
      channel: target.is_a?(Channel) ? target : nil,
      target: target.is_a?(Channel) ? nil : target,
      sender: @server.nickname,
      content: action_text,
      message_type: "action"
    )

    send_irc_command("action", target: target_name, message: action_text)
  end

  def send_pm(nick, content)
    @message = Message.create!(
      server: @server,
      channel: nil,
      target: nick,
      sender: @server.nickname,
      content: content,
      message_type: "privmsg"
    )

    send_irc_command("privmsg", target: nick, message: content)
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
    flash[:alert] = "Server not connected"
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
  rescue InternalApiClient::ConnectionNotFound
    flash[:alert] = "Server not connected"
  rescue InternalApiClient::ServiceUnavailable
    flash[:alert] = "IRC service unavailable"
  end
end
