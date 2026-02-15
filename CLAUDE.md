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

## Troubleshooting `bin/dev`

If `bin/dev` fails, run `bin/dev --verbose` to see the actual error.

Common causes:

- **Stale `.overmind.sock`** — Make sure no overmind process is already running. Kill it if so, then remove `.overmind.sock`.
- **Stale PID files** — `bin/dev` starts two Rails servers. Check `tmp/pids/` for leftover PID files that didn't clean up. Kill any zombie server processes and remove the stale PID files.
- **Port clash** — `bin/dev` starts two servers on consecutive ports (default 3000 and 3001). If a port is taken by another service, use `-p` to pick a different base port (e.g. `bin/dev -p 3005` for 3005 and 3006).
