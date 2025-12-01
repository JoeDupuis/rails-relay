class IrcConnection
  def initialize(server_id:, user_id:, config:, on_event:)
    @server_id = server_id
    @user_id = user_id
    @config = config
    @on_event = on_event
    @running = false
    @thread = nil
    @client = nil
    @command_queue = Queue.new
  end

  def start
    @running = true
    @thread = Thread.new { run }
  end

  def stop
    @running = false
    @command_queue << { command: "quit" }
    @thread&.join(5)
    @thread&.kill if @thread&.alive?
  end

  def execute(command, params)
    @command_queue << { command: command, params: params }
  end

  def running?
    @running
  end

  def alive?
    @thread&.alive? || false
  end

  private

  def run
    connect
    event_loop
  rescue => e
    @on_event.call(type: "error", message: e.message)
    Rails.logger.error "IRC connection error: #{e.message}\n#{e.backtrace.join("\n")}"
  ensure
    cleanup
  end

  def connect
    @client = Yaic::Client.new(
      server: @config[:address],
      port: @config[:port],
      ssl: @config[:ssl],
      verify_ssl: @config.fetch(:ssl_verify, true),
      nickname: @config[:nickname],
      username: @config[:username] || @config[:nickname],
      realname: @config[:realname] || @config[:nickname]
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
  end

  def event_loop
    while @running && @client.connected?
      process_commands
      sleep 0.1
    end
  end

  def process_commands
    while (cmd = @command_queue.pop(true) rescue nil)
      execute_command(cmd)
    end
  end

  def execute_command(cmd)
    case cmd[:command]
    when "join"
      @client.join(cmd[:params][:channel])
    when "part"
      @client.part(cmd[:params][:channel], cmd[:params][:message])
    when "privmsg"
      @client.privmsg(cmd[:params][:target], cmd[:params][:message])
    when "notice"
      @client.notice(cmd[:params][:target], cmd[:params][:message])
    when "action"
      @client.privmsg(cmd[:params][:target], "\x01ACTION #{cmd[:params][:message]}\x01")
    when "nick"
      @client.nick(cmd[:params][:nickname])
    when "quit"
      @running = false
      @client.quit(cmd[:params]&.[](:message))
    end
  end

  def cleanup
    @client&.quit if @client&.connected?
    @on_event.call(type: "disconnected")
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
    {
      channel: event.channel,
      names: event.users
    }
  end
end
