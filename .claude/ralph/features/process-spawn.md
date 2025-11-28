# IRC Process Spawning

## Description

The Rails app spawns separate Ruby processes to maintain persistent IRC connections. Each Server has its own process. These processes survive Rails restarts.

This feature covers spawning, stopping, and basic lifecycle of IRC processes. Actual IRC protocol handling is in the irc-client gem (external dependency).

## Behavior

### Starting a Connection

When user clicks "Connect" on a server:
1. Rails spawns a new Ruby process
2. Process loads Rails environment (has access to models)
3. Process stores its PID in the Server record
4. Process creates a Unix socket for receiving commands
5. Process connects to IRC server using irc-client gem
6. On successful connect, process broadcasts status via Solid Cable
7. Rails updates `server.connected_at`

### Stopping a Connection

When user clicks "Disconnect":
1. Rails sends shutdown command to process via Unix socket
2. Process sends QUIT to IRC server
3. Process cleans up and exits
4. Rails clears `server.process_pid`, `server.socket_path`, `server.connected_at`

### Process Communication

**Rails → Process (commands):**
- Unix socket at `tmp/sockets/irc_server_{id}.sock`
- Commands: join channel, part channel, send message, quit

**Process → Rails (events):**
- Process writes directly to database (Message.create, etc.)
- Solid Cable broadcasts automatically via model callbacks
- Process can also broadcast directly for status updates

### Health Check

On Rails boot (and periodically):
1. For each Server where `process_pid` is not null
2. Check if process is alive (`Process.kill(0, pid)`)
3. If dead: clear pid/socket, optionally respawn if was connected

### Process Startup Command

```bash
bundle exec rails runner "IrcProcess.run(server_id: ID)"
```

Or a dedicated script:
```bash
bin/irc_connect SERVER_ID
```

## Models

Server fields used:
- `process_pid` - PID of running process
- `socket_path` - Path to Unix socket for commands
- `connected_at` - When connection was established

## IrcProcess Class

```ruby
# app/models/irc_process.rb (or lib/)
class IrcProcess
  def self.run(server_id:)
    new(server_id).run
  end
  
  def initialize(server_id)
    @server = Server.find(server_id)
  end
  
  def run
    setup_socket
    setup_signal_handlers
    connect_to_irc
    run_event_loop
  ensure
    cleanup
  end
  
  private
  
  def setup_socket
    @socket_path = "tmp/sockets/irc_server_#{@server.id}.sock"
    @server.update!(socket_path: @socket_path, process_pid: Process.pid)
    # Create Unix socket server...
  end
  
  def connect_to_irc
    @client = Irc::Client.new(
      server: @server.address,
      port: @server.port,
      ssl: @server.ssl,
      nickname: @server.nickname
      # ...
    )
    
    @client.on(:message) { |event| handle_message(event) }
    @client.on(:join) { |event| handle_join(event) }
    # ... other handlers
    
    @client.connect
    @server.update!(connected_at: Time.current)
    broadcast_status(:connected)
  end
  
  def handle_message(event)
    # Activate tenant for this user
    Tenant.switch(@server.user) do
      Message.create!(
        server: @server,
        channel: find_or_create_channel(event.target),
        sender: event.nick,
        content: event.message,
        message_type: "privmsg"
      )
      # Solid Cable broadcast happens via model callback
    end
  end
  
  def run_event_loop
    loop do
      # Check Unix socket for commands
      # Process IRC events via client
      # Handle signals
    end
  end
end
```

## IrcProcessManager

```ruby
# app/models/irc_process_manager.rb
class IrcProcessManager
  def self.spawn(server)
    pid = Process.spawn(
      "bundle", "exec", "rails", "runner",
      "IrcProcess.run(server_id: #{server.id})",
      pgroup: true  # New process group, survives Rails restart
    )
    Process.detach(pid)
    pid
  end
  
  def self.stop(server)
    return unless server.socket_path && File.exist?(server.socket_path)
    
    socket = UNIXSocket.new(server.socket_path)
    socket.puts(JSON.generate({ command: "quit" }))
    socket.close
    
    # Wait briefly for graceful shutdown
    sleep 1
    
    # Force kill if still alive
    if server.process_pid && process_alive?(server.process_pid)
      Process.kill("TERM", server.process_pid)
    end
  end
  
  def self.process_alive?(pid)
    Process.kill(0, pid)
    true
  rescue Errno::ESRCH
    false
  end
  
  def self.health_check_all
    Server.where.not(process_pid: nil).find_each do |server|
      unless process_alive?(server.process_pid)
        server.update!(process_pid: nil, socket_path: nil, connected_at: nil)
        # Optionally respawn if user wants auto-reconnect
      end
    end
  end
end
```

## Tests

### Unit: IrcProcessManager

**spawn creates a detached process**
- Call IrcProcessManager.spawn(server)
- Assert server.process_pid is set
- Assert process is running (Process.kill(0, pid) doesn't raise)

**stop sends quit command and clears server fields**
- Have running process with socket
- Call IrcProcessManager.stop(server)
- Assert server.process_pid is nil
- Assert server.socket_path is nil
- Assert server.connected_at is nil

**process_alive? returns true for running process**
**process_alive? returns false for dead process**

**health_check_all clears dead processes**
- Create server with fake PID (not running)
- Call health_check_all
- Assert server.process_pid is now nil

### Controller: Server Connection Actions

**POST /servers/:id/connection (connect)**
- Spawns process
- Redirects to server show

**DELETE /servers/:id/connection (disconnect)**
- Stops process
- Redirects to server show

### Integration: Connect and Disconnect

**User connects to server**
- Have server configured
- Visit server page
- Click Connect
- See status change to "Connecting..." then "Connected"
- Process is running

**User disconnects from server**
- Have connected server
- Click Disconnect
- See status change to "Disconnected"
- Process is stopped

## Implementation Notes

- Unix sockets are created in `tmp/sockets/` - ensure directory exists
- Process runs in separate process group (`pgroup: true`) to survive Rails restart
- Use `Process.detach` so Rails doesn't wait for process
- Signal handlers (TERM, INT) should trigger graceful shutdown
- Multi-tenant: Process must activate correct tenant before DB operations

## Routes

```ruby
# For connect/disconnect, create a resource
resource :connection, only: [:create, :destroy], controller: 'server_connections'
# Nested under server
resources :servers do
  resource :connection, only: [:create, :destroy]
end
```

This gives us:
- POST /servers/:server_id/connection → connect
- DELETE /servers/:server_id/connection → disconnect

## Dependencies

- Requires `server-crud.md` (Server model)
- Requires `auth-multitenant.md` (tenant switching in process)
- Requires irc-client gem (external)
