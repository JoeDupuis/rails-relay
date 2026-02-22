# Rails Relay

A web-based IRC client built with Rails and Hotwire.

## Architecture

The app runs as two Rails processes sharing the same codebase:

- **Main app** - Handles views/UI, can be restarted freely
- **Internal app** - API that holds IRC connections via the `yaic` gem; restarting kills all connections

## Mobile Apps

- **Android** - `android/` folder, uses Hotwire Native
- **iOS** - `ios/` folder (planned), will use Hotwire Native

## Setup

```bash
bin/setup
bin/dev
```

`bin/dev` starts two servers on consecutive ports (default 3000 and 3001). If either port is taken, use `-p` to pick a different base port (e.g. `bin/dev -p 3005` for 3005 and 3006). Stale PID files, overmind sockets, and zombie processes are cleaned up automatically on startup.
