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
