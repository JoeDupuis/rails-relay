# Rails Relay

A web-based IRC client built with Rails and Hotwire.

## Architecture

The app runs as two Rails processes sharing the same codebase.

### Why two processes?

Rails code reloading kills all threads. In a single process, every code change would disconnect all IRC connections. Splitting into two processes means the main app (UI) can restart freely while the internal app holds connections alive.

### Main app (port 3000)

Handles all web UI, views, controllers, and Turbo broadcasts. Sends IRC commands by calling `InternalApiClient` which makes HTTP requests to the internal app. Receives IRC events via `Internal::Irc::EventsController` → `IrcEventHandler`, which persists to DB and broadcasts via Turbo Streams.

### Internal app (port 3001)

Runs `IrcConnectionManager` (singleton) — one background thread per connected server, each owning a `Yaic::Client` instance. Exposes a REST API to create/destroy connections, send commands, and query status. When IRC events arrive from the server, it serializes them and POSTs back to the main app. Auth between the two processes uses a shared `INTERNAL_API_SECRET` as a Bearer token.

### Communication flow

```
User action → Main app → InternalApiClient.send_command() → HTTP → Internal app
IRC event → Yaic::Client → IrcConnectionManager → InternalApiClient.post_event() → HTTP → Main app → IrcEventHandler → DB + Turbo broadcast
```

### Yaic gem

Yaic ("Yet Another IRC Client") is a Ruby IRC client library. It provides a thread-safe, event-driven API for IRC servers. `Yaic::Client.new(server:, port:, ssl:, nickname:, ...)` connects and exposes IRC commands (`join`, `part`, `privmsg`, `notice`, `nick`, `topic`, `ison`, etc.). Events are received via `client.on(:message) { |e| ... }` handlers that run on a background read thread. It maintains channel/user state in memory (`client.channels["#ruby"].users`).

## Mobile Apps

- **Android** - `android/` folder, uses Hotwire Native
- **iOS** - `ios/` folder (planned), will use Hotwire Native

## Setup

```bash
bin/setup
bin/dev
```

`bin/dev` starts two servers on consecutive ports (default 3000 and 3001). If either port is taken, use `-p` to pick a different base port (e.g. `bin/dev -p 3005` for 3005 and 3006). Stale PID files, overmind sockets, and zombie processes are cleaned up automatically on startup.
