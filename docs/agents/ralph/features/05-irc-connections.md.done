# IRC Connection Management

## Description

The `IrcConnectionManager` singleton manages IRC connections as threads. Each connection uses the `yaic` gem to communicate with IRC servers. Events are sent back via the internal API.

**Development**: Threads run in the web process.
**Production**: Threads run in a separate IRC service process with no-recycle Puma config.

## IrcConnectionManager

Singleton that manages all active connections:

```ruby
# app/services/irc_connection_manager.rb
class IrcConnectionManager
  include Singleton

  def initialize
    @connections = {}
    @mutex = Mutex.new
  end

  def start(server_id:, user_id:, config:)
    @mutex.synchronize do
      return false if @connections[server_id]

      connection = IrcConnection.new(
        server_id: server_id,
        user_id: user_id,
        config: config,
        on_event: ->(event) { notify_web_service(server_id, user_id, event) }
      )

      @connections[server_id] = connection
      connection.start
      true
    end
  end

  def stop(server_id)
    @mutex.synchronize do
      connection = @connections.delete(server_id)
      connection&.stop
      connection.present?
    end
  end

  def send_command(server_id, command, params)
    @mutex.synchronize do
      connection = @connections[server_id]
      return false unless connection

      connection.execute(command, params)
      true
    end
  end

  def active_connections
    @mutex.synchronize { @connections.keys }
  end

  def connected?(server_id)
    @mutex.synchronize { @connections.key?(server_id) }
  end

  private

  def notify_web_service(server_id, user_id, event)
    InternalApiClient.post_event(
      server_id: server_id,
      user_id: user_id,
      event: event
    )
  rescue InternalApiClient::ServiceUnavailable => e
    Rails.logger.error "Failed to post event: #{e.message}"
  end
end
```

## IrcConnection

Thread wrapper around yaic client:

```ruby
# app/services/irc_connection.rb
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
    @client.on(:join) { |e| @on_event.call(type: "join", data: serialize_event(e)) }
    @client.on(:part) { |e| @on_event.call(type: "part", data: serialize_event(e)) }
    @client.on(:quit) { |e| @on_event.call(type: "quit", data: serialize_event(e)) }
    @client.on(:topic) { |e| @on_event.call(type: "topic", data: serialize_event(e)) }
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
      @client.action(cmd[:params][:target], cmd[:params][:message])
    when "nick"
      @client.nick(cmd[:params][:nickname])
    when "quit"
      @running = false
      @client.quit(cmd[:params][:message])
    end
  end

  def cleanup
    @client&.quit if @client&.connected?
    @on_event.call(type: "disconnected")
  end

  def serialize_event(event)
    {
      source: event.source&.to_s,
      target: event.target,
      text: event.text
    }
  end

  def serialize_nick_event(event)
    {
      source: event.source&.to_s,
      new_nick: event.new_nick
    }
  end

  def serialize_kick_event(event)
    {
      source: event.source&.to_s,
      target: event.channel,
      kicked: event.kicked,
      text: event.reason
    }
  end

  def serialize_names_event(event)
    {
      channel: event.channel,
      names: event.names
    }
  end
end
```

## User-Facing Controller

```ruby
# app/controllers/connections_controller.rb
class ConnectionsController < ApplicationController
  before_action :set_server

  def create
    InternalApiClient.start_connection(
      server_id: @server.id,
      user_id: Current.user.id,
      config: {
        address: @server.address,
        port: @server.port,
        ssl: @server.ssl,
        nickname: @server.nickname,
        username: @server.username,
        realname: @server.realname
      }
    )
    redirect_to @server, notice: "Connecting..."
  rescue InternalApiClient::ServiceUnavailable
    redirect_to @server, alert: "IRC service unavailable"
  end

  def destroy
    InternalApiClient.stop_connection(server_id: @server.id)
    redirect_to @server, notice: "Disconnecting..."
  rescue InternalApiClient::ServiceUnavailable
    redirect_to @server, alert: "IRC service unavailable"
  end

  private

  def set_server
    @server = Server.find(params[:server_id])
  end
end
```

## Production Setup

### bin/irc_service

```bash
#!/usr/bin/env bash
exec bundle exec puma -C config/puma/irc_service.rb
```

### config/puma/irc_service.rb

```ruby
workers 0
threads 1, 1

port ENV.fetch("IRC_SERVICE_PORT", 3001)

environment ENV.fetch("RAILS_ENV", "production")

# No recycling - threads must survive for life of process
```

### Deployment

Run two containers/processes:
- **Web**: `bin/rails server` (normal Puma config)
- **IRC**: `bin/irc_service` (single worker, no recycling)

## Routes

```ruby
resources :servers do
  resource :connection, only: [:create, :destroy]
end
```

## Tests

### Unit: IrcConnectionManager

**start creates a new connection**
- Call manager.start(server_id: 1, user_id: 1, config: {...})
- Assert 1 is in active_connections
- Assert returns true

**start returns false for duplicate server_id**
- Start connection for server 1
- Start connection for server 1 again
- Assert returns false
- Assert still only one connection

**stop removes connection and returns true**
- Start connection
- Call manager.stop(1)
- Assert active_connections is empty
- Assert returns true

**stop returns false for non-existent connection**
- Call manager.stop(999)
- Assert returns false

**send_command routes to connection**
- Start connection with mock IrcConnection
- Call send_command(1, "join", { channel: "#test" })
- Assert mock received execute call
- Assert returns true

**send_command returns false for non-existent connection**
- Call send_command(999, "join", { channel: "#test" })
- Assert returns false

**connected? returns true for active connection**
**connected? returns false for non-existent connection**

**active_connections returns array of server_ids**
- Start connections for servers 1, 2, 3
- Assert active_connections == [1, 2, 3]

### Unit: IrcConnection

**start spawns thread**
- Create connection
- Call start
- Assert thread is alive

**stop signals thread to exit**
- Start connection with mock client
- Call stop
- Assert thread is not alive
- Assert client.quit was called

**execute queues command**
- Start connection
- Call execute("join", { channel: "#test" })
- Assert command appears in queue

**process_commands executes queued commands**
- Have connection with mock client
- Queue join command
- Call process_commands
- Assert client.join was called

**on_event callback is called for IRC events**
- Create connection with event callback
- Simulate IRC message event
- Assert callback was called with correct data

### Controller: ConnectionsController

**POST /servers/:id/connection calls InternalApiClient**
- Stub InternalApiClient
- POST to create connection
- Assert InternalApiClient.start_connection called with correct params
- Assert redirects to server

**POST /servers/:id/connection handles service unavailable**
- Stub InternalApiClient to raise ServiceUnavailable
- POST to create connection
- Assert redirects with alert

**DELETE /servers/:id/connection calls InternalApiClient**
- Stub InternalApiClient
- DELETE connection
- Assert InternalApiClient.stop_connection called
- Assert redirects to server

### Integration: Connect and Disconnect

**User connects to server**
- Have server configured
- Visit server page
- Click Connect
- POST to internal API (stubbed)
- Simulate connected event via POST to /internal/irc/events
- Assert server shows as connected

**User disconnects from server**
- Have connected server
- Click Disconnect
- POST to internal API (stubbed)
- Simulate disconnected event via POST to /internal/irc/events
- Assert server shows as disconnected

## Implementation Notes

- IrcConnectionManager is a Singleton - one instance per process
- Thread safety via Mutex for connection registry
- Command queue (Ruby Queue) is thread-safe
- In dev, everything runs in web process
- In prod, IRC service is separate with no-recycle Puma
- yaic events may need different serialization - check gem docs

## Dependencies

- Requires `03-server-crud.md` (Server model)
- Requires `04-internal-api.md` (InternalApiClient)
- Requires `yaic` gem
