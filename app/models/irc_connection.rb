class IrcConnection
  def initialize(server_id:, user_id:, config:, on_event:)
    @server_id = server_id
    @user_id = user_id
    @config = config
    @on_event = on_event
    @running = false
    @thread = nil
    @client = nil
    @error_message = nil
  end

  THREAD_PREFIX = "rails_relay_irc_"
  STOP_TIMEOUT = 3

  def start
    @running = true
    @thread = Thread.new { run }
    @thread.name = "#{THREAD_PREFIX}#{@server_id}"
  end

  def stop
    @running = false
    quit_client
    @thread&.join(STOP_TIMEOUT)
    @thread&.kill if @thread&.alive?
  end

  def execute(command, params)
    execute_command(command: command, params: params)
  end

  def running?
    @running
  end

  def alive?
    @thread&.alive? || false
  end

  def connected?
    @client&.connected? || false
  end

  def ison(nicks)
    connected_client.ison(nicks)
  end

  private

  def run
    connect
    event_loop
  rescue => e
    report_error(e) if @running
  ensure
    cleanup
  end

  def report_error(error)
    @error_message = error.message
    @on_event.call(type: "error", message: error.message)
    Rails.logger.error "[IRC-#{@server_id}] Connection error: #{error.message}"
  end

  def connect
    @client = Yaic::Client.new(
      server: @config[:address],
      port: @config[:port],
      ssl: @config[:ssl],
      verify_ssl: @config.fetch(:ssl_verify, true),
      nickname: @config[:nickname],
      username: @config[:username] || @config[:nickname],
      realname: @config[:realname] || @config[:nickname],
      password: @config[:password]
    )

    setup_handlers
    @client.connect
    @on_event.call(type: "connected")
  end

  def setup_handlers
    @client.on(:message) { |e| @on_event.call(type: "message", data: serialize_event(e)) }
    @client.on(:action) { |e| @on_event.call(type: "action", data: serialize_event(e)) }
    @client.on(:notice) { |e| @on_event.call(type: "notice", data: serialize_event(e)) }
    @client.on(:join) { |e| @on_event.call(type: "join", data: serialize_join_event(e)) }
    @client.on(:part) { |e| @on_event.call(type: "part", data: serialize_part_event(e)) }
    @client.on(:quit) { |e| @on_event.call(type: "quit", data: serialize_quit_event(e)) }
    @client.on(:topic) { |e| @on_event.call(type: "topic", data: serialize_topic_event(e)) }
    @client.on(:nick) { |e| @on_event.call(type: "nick", data: serialize_nick_event(e)) }
    @client.on(:kick) { |e| @on_event.call(type: "kick", data: serialize_kick_event(e)) }
    @client.on(:names) { |e| @on_event.call(type: "names", data: serialize_names_event(e)) }
    @client.on(:error) { |e| handle_error_event(e) }
  end

  def event_loop
    while @running && @client.connected?
      sleep 0.1
    end
  end

  def connected_client
    client = @client
    raise Yaic::ConnectionError, "Not connected" unless client&.connected?
    client
  end

  def execute_command(command:, params:)
    client = connected_client

    case command
    when "join"
      client.join(params[:channel])
      nil
    when "part"
      client.part(params[:channel], params[:message])
      nil
    when "privmsg"
      client.privmsg(params[:target], params[:message])
    when "notice"
      client.notice(params[:target], params[:message])
    when "action"
      parts = client.privmsg(params[:target], "\x01ACTION #{params[:message]}\x01")
      parts&.map { |part| part.delete_prefix("\x01ACTION ").delete_suffix("\x01") }
    when "nick"
      client.nick(params[:nickname])
      nil
    end
  end

  def quit_client
    @client&.quit
  rescue StandardError => e
    Rails.logger.warn "[IRC-#{@server_id}] Quit failed: #{e.class}: #{e.message}"
  end

  def cleanup
    quit_client
    reason = @client&.disconnect_reason || @error_message
    Rails.logger.info "[IRC-#{@server_id}] Disconnected: #{reason || "stopped"}"
    @on_event.call(type: "disconnected", reason: reason)
  rescue StandardError => e
    Rails.logger.error "[IRC-#{@server_id}] Cleanup failed: #{e.class}: #{e.message}"
  end

  def serialize_event(event)
    {
      source: event.source&.raw,
      target: event.target,
      text: event.text
    }
  end

  def serialize_join_event(event)
    {
      source: event.user&.raw,
      target: event.channel
    }
  end

  def serialize_part_event(event)
    {
      source: event.user&.raw,
      target: event.channel,
      text: event.reason
    }
  end

  def serialize_quit_event(event)
    {
      source: event.user&.raw,
      text: event.reason
    }
  end

  def serialize_topic_event(event)
    {
      source: event.setter&.raw,
      target: event.channel,
      text: event.topic
    }
  end

  def serialize_nick_event(event)
    {
      source: event.old_nick,
      new_nick: event.new_nick
    }
  end

  def serialize_kick_event(event)
    {
      source: event.by&.raw,
      target: event.channel,
      kicked: event.user,
      text: event.reason
    }
  end

  def serialize_names_event(event)
    names = event.users.map do |nick, modes|
      prefix = if modes.include?(:op)
        "@"
      elsif modes.include?(:voice)
        "+"
      else
        ""
      end
      "#{prefix}#{nick}"
    end

    {
      channel: event.channel,
      names: names
    }
  end

  def handle_error_event(event)
    if (exception = event[:exception])
      Rails.logger.error "[IRC-#{@server_id}] #{exception.class}: #{exception.message}"
      return
    end

    case event[:numeric]
    when 401
      nick = event.params[1]
      @on_event.call(type: "no_such_nick", data: { nick: nick })
    end
  end
end
