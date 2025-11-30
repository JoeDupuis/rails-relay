# Process Communication (IPC)

## Description

Rails needs to send commands to running IRC processes (join channel, send message, etc.). IRC processes need to notify Rails of events (messages received, status changes).

This feature implements the communication layer between Rails and IRC processes.

## Behavior

### Rails → Process: Sending Commands

Rails sends commands via Unix socket. Each IRC process listens on its socket for JSON commands.

**Command format:**
```json
{
  "command": "privmsg",
  "target": "#ruby",
  "message": "Hello, world!"
}
```

**Available commands:**
- `join` - Join a channel: `{ "command": "join", "channel": "#ruby" }`
- `part` - Leave a channel: `{ "command": "part", "channel": "#ruby", "message": "Goodbye" }`
- `privmsg` - Send message: `{ "command": "privmsg", "target": "#ruby", "message": "Hello" }`
- `notice` - Send notice: `{ "command": "notice", "target": "#ruby", "message": "Notice" }`
- `nick` - Change nick: `{ "command": "nick", "nickname": "newnick" }`
- `quit` - Disconnect: `{ "command": "quit", "message": "Goodbye" }`

### Process → Rails: Events and Data

**Database writes:**
Process writes directly to database when events occur. Models have callbacks that broadcast via Solid Cable.

```ruby
# In IRC process
Message.create!(server: @server, channel: channel, sender: nick, content: text, message_type: "privmsg")
# Model callback broadcasts to Solid Cable automatically
```

**Status broadcasts:**
Process broadcasts status changes directly to Solid Cable for immediate UI updates.

```ruby
# In IRC process
ActionCable.server.broadcast("server_#{@server.id}_status", { status: "connected" })
```

### ServiceBus Module

A helper for pub/sub communication:

```ruby
# lib/service_bus.rb
module ServiceBus
  def self.publish(channel, data)
    ActionCable.server.broadcast(channel, data)
  end
  
  def self.subscribe(channel, &block)
    callback = ->(message) { block.call(JSON.parse(message)) }
    ActionCable.server.pubsub.subscribe(channel, callback)
    -> { ActionCable.server.pubsub.unsubscribe(channel, callback) }
  end
end
```

### IrcCommandSender

Rails-side helper to send commands to IRC process:

```ruby
# app/models/irc_command_sender.rb
class IrcCommandSender
  def initialize(server)
    @server = server
  end
  
  def send_command(command_hash)
    raise "Server not connected" unless @server.socket_path
    raise "Socket not found" unless File.exist?(@server.socket_path)
    
    socket = UNIXSocket.new(@server.socket_path)
    socket.puts(JSON.generate(command_hash))
    socket.close
  end
  
  def join(channel)
    send_command(command: "join", channel: channel)
  end
  
  def part(channel, message = nil)
    send_command(command: "part", channel: channel, message: message)
  end
  
  def privmsg(target, message)
    send_command(command: "privmsg", target: target, message: message)
  end
  
  def quit(message = nil)
    send_command(command: "quit", message: message)
  end
end
```

### IrcProcess Socket Handler

Process-side handler for incoming commands:

```ruby
# In IrcProcess
def setup_socket
  File.delete(@socket_path) if File.exist?(@socket_path)
  @socket_server = UNIXServer.new(@socket_path)
  File.chmod(0600, @socket_path)  # Only owner can access
end

def check_socket
  return unless IO.select([@socket_server], nil, nil, 0)
  
  client = @socket_server.accept_nonblock
  data = client.gets
  client.close
  
  command = JSON.parse(data)
  handle_command(command)
rescue IO::WaitReadable
  # No data available
end

def handle_command(command)
  case command["command"]
  when "join"
    @client.join(command["channel"])
  when "part"
    @client.part(command["channel"], command["message"])
  when "privmsg"
    @client.privmsg(command["target"], command["message"])
  when "notice"
    @client.notice(command["target"], command["message"])
  when "nick"
    @client.nick(command["nickname"])
  when "quit"
    @running = false
    @client.quit(command["message"])
  end
end
```

## Models

### Message Callbacks

```ruby
# app/models/message.rb
class Message < ApplicationRecord
  after_create_commit :broadcast_to_channel
  
  private
  
  def broadcast_to_channel
    if channel
      broadcast_append_to channel, target: "messages"
    end
  end
end
```

## Tests

### Unit: IrcCommandSender

**join sends join command to socket**
- Create mock socket
- Call sender.join("#ruby")
- Assert socket received `{"command":"join","channel":"#ruby"}`

**privmsg sends privmsg command**
- Call sender.privmsg("#ruby", "Hello")
- Assert socket received correct JSON

**raises error when server not connected**
- Server has no socket_path
- Assert raises "Server not connected"

**raises error when socket file missing**
- Server has socket_path but file doesn't exist
- Assert raises "Socket not found"

### Unit: ServiceBus

**publish broadcasts to channel**
- Call ServiceBus.publish("test_channel", { foo: "bar" })
- Assert ActionCable received broadcast

**subscribe receives messages**
- Subscribe to channel with block
- Publish to channel
- Assert block was called with data

### Integration: Send Message Flow

**User sends message to channel**
- Have connected server with joined channel
- POST to messages create with content
- Assert command sent to IRC process
- Assert message appears in UI (via Turbo Stream)

## Implementation Notes

- Socket files in `tmp/sockets/` - clean up on process exit
- Socket permissions 0600 for security
- JSON for command format - simple and debuggable
- Non-blocking socket reads in process event loop
- Consider timeout for socket operations

## Dependencies

- Requires `process-spawn.md` (process lifecycle)
