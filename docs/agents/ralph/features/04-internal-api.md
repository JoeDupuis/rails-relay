# Internal API

## Description

The internal API enables communication between the web service and IRC connection threads. It's used for:
- Starting/stopping IRC connections
- Sending commands (join, part, privmsg)
- Receiving events from IRC (messages, joins, parts, etc.)

In development, the app calls its own endpoints. In production, two separate processes communicate via HTTP.

## Configuration

```ruby
# config/environments/development.rb
config.irc_service_url = "http://localhost:3000"  # Same process
config.web_service_url = "http://localhost:3000"

# config/environments/production.rb
config.irc_service_url = ENV.fetch("IRC_SERVICE_URL")
config.web_service_url = ENV.fetch("WEB_SERVICE_URL")
```

Environment variable:
- `INTERNAL_API_SECRET` - Shared secret for authentication

## Endpoints

```
POST   /internal/irc/connections      # Start connection for a server
DELETE /internal/irc/connections/:id  # Stop connection
POST   /internal/irc/commands         # Send command to IRC
GET    /internal/irc/status           # Health check, list active connections
POST   /internal/irc/events           # Receive events from IRC threads
```

## Authentication

All requests require Bearer token:
```
Authorization: Bearer <INTERNAL_API_SECRET>
```

```ruby
# app/controllers/concerns/internal_api_authentication.rb
module InternalApiAuthentication
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_internal_api!
  end

  private

  def authenticate_internal_api!
    expected = ENV.fetch("INTERNAL_API_SECRET")
    provided = request.headers["Authorization"]&.delete_prefix("Bearer ")

    head :unauthorized unless ActiveSupport::SecurityUtils.secure_compare(expected.to_s, provided.to_s)
  end
end
```

## Endpoint Details

### POST /internal/irc/connections

Start a new IRC connection.

**Request:**
```json
{
  "server_id": 1,
  "user_id": 1,
  "config": {
    "address": "irc.libera.chat",
    "port": 6697,
    "ssl": true,
    "nickname": "mynick",
    "username": "myuser",
    "realname": "My Name"
  }
}
```

**Response:** `202 Accepted`

### DELETE /internal/irc/connections/:id

Stop an IRC connection.

**Response:** `200 OK`

### POST /internal/irc/commands

Send a command to an active IRC connection.

**Request:**
```json
{
  "server_id": 1,
  "command": "privmsg",
  "params": {
    "target": "#ruby",
    "message": "Hello!"
  }
}
```

**Commands:**
| command | params |
|---------|--------|
| join | `{ channel: "#ruby" }` |
| part | `{ channel: "#ruby", message: "Goodbye" }` |
| privmsg | `{ target: "#ruby", message: "Hello" }` |
| notice | `{ target: "#ruby", message: "Notice" }` |
| nick | `{ nickname: "newnick" }` |
| action | `{ target: "#ruby", message: "waves" }` |

**Response:** `202 Accepted` or `404 Not Found` (if connection doesn't exist)

### GET /internal/irc/status

Health check and list of active connections.

**Response:**
```json
{
  "status": "ok",
  "connections": [1, 3, 5]
}
```

### POST /internal/irc/events

Receive events from IRC threads. Called by the IRC connection when events occur.

**Request:**
```json
{
  "server_id": 1,
  "user_id": 1,
  "event": {
    "type": "message",
    "data": {
      "source": "nick!user@host",
      "target": "#channel",
      "text": "Hello everyone"
    }
  }
}
```

**Event types:**
| type | data fields |
|------|-------------|
| connected | (none) |
| disconnected | (none) |
| message | source, target, text |
| action | source, target, text |
| notice | source, target, text |
| join | source, target |
| part | source, target, text |
| quit | source, text |
| kick | source, target, kicked, text |
| nick | source, new_nick |
| topic | source, target, text |
| names | channel, names[] |

**Response:** `200 OK`

## Controllers

```ruby
# app/controllers/internal/irc/connections_controller.rb
module Internal
  module Irc
    class ConnectionsController < ApplicationController
      include InternalApiAuthentication
      skip_before_action :verify_authenticity_token

      def create
        IrcConnectionManager.instance.start(
          server_id: params[:server_id],
          user_id: params[:user_id],
          config: params[:config].to_unsafe_h.symbolize_keys
        )
        head :accepted
      end

      def destroy
        IrcConnectionManager.instance.stop(params[:id].to_i)
        head :ok
      end
    end
  end
end
```

```ruby
# app/controllers/internal/irc/commands_controller.rb
module Internal
  module Irc
    class CommandsController < ApplicationController
      include InternalApiAuthentication
      skip_before_action :verify_authenticity_token

      def create
        result = IrcConnectionManager.instance.send_command(
          params[:server_id].to_i,
          params[:command],
          params[:params]&.to_unsafe_h&.symbolize_keys || {}
        )

        if result
          head :accepted
        else
          head :not_found
        end
      end
    end
  end
end
```

```ruby
# app/controllers/internal/irc/status_controller.rb
module Internal
  module Irc
    class StatusController < ApplicationController
      include InternalApiAuthentication

      def show
        render json: {
          status: "ok",
          connections: IrcConnectionManager.instance.active_connections
        }
      end
    end
  end
end
```

```ruby
# app/controllers/internal/irc/events_controller.rb
module Internal
  module Irc
    class EventsController < ApplicationController
      include InternalApiAuthentication
      skip_before_action :verify_authenticity_token

      def create
        # User.find queries the main (shared) database, not the tenant DB
        user = User.find(params[:user_id])
        server_id = params[:server_id]
        event = params[:event]

        # Set Current.user_id for use in model callbacks (e.g., Turbo broadcasts)
        Current.user_id = user.id

        Tenant.switch(user) do
          # Inside this block, all tenant model queries (Server, Channel, etc.)
          # are scoped to this user's database
          server = Server.find(server_id)
          IrcEventHandler.handle(server, event)
        end

        head :ok
      end
    end
  end
end
```

## Internal API Client

```ruby
# app/services/internal_api_client.rb
class InternalApiClient
  class ServiceUnavailable < StandardError; end
  class ConnectionNotFound < StandardError; end

  class << self
    def start_connection(server_id:, user_id:, config:)
      post(irc_service_url("/internal/irc/connections"), {
        server_id: server_id,
        user_id: user_id,
        config: config
      })
    end

    def stop_connection(server_id:)
      delete(irc_service_url("/internal/irc/connections/#{server_id}"))
    end

    def send_command(server_id:, command:, params:)
      response = post(irc_service_url("/internal/irc/commands"), {
        server_id: server_id,
        command: command,
        params: params
      })

      case response.status
      when 202 then true
      when 404 then raise ConnectionNotFound, "Server #{server_id} not connected"
      else raise ServiceUnavailable, "IRC service error: #{response.status}"
      end
    end

    def post_event(server_id:, user_id:, event:)
      post(web_service_url("/internal/irc/events"), {
        server_id: server_id,
        user_id: user_id,
        event: event
      })
    end

    def status
      get(irc_service_url("/internal/irc/status"))
    end

    private

    def irc_service_url(path)
      Rails.configuration.irc_service_url + path
    end

    def web_service_url(path)
      Rails.configuration.web_service_url + path
    end

    def post(url, body)
      HTTP.auth("Bearer #{secret}").post(url, json: body)
    rescue HTTP::Error => e
      raise ServiceUnavailable, "Service unreachable: #{e.message}"
    end

    def get(url)
      HTTP.auth("Bearer #{secret}").get(url)
    rescue HTTP::Error => e
      raise ServiceUnavailable, "Service unreachable: #{e.message}"
    end

    def delete(url)
      HTTP.auth("Bearer #{secret}").delete(url)
    rescue HTTP::Error => e
      raise ServiceUnavailable, "Service unreachable: #{e.message}"
    end

    def secret
      ENV.fetch("INTERNAL_API_SECRET")
    end
  end
end
```

## Routes

```ruby
# config/routes.rb
namespace :internal do
  namespace :irc do
    resources :connections, only: [:create, :destroy]
    resources :commands, only: [:create]
    resources :events, only: [:create]
    resource :status, only: [:show]
  end
end
```

## Tests

### Controller: Internal::Irc::ConnectionsController

**POST /internal/irc/connections with valid secret**
- POST with Authorization header and valid payload
- Assert 202 accepted
- Assert IrcConnectionManager.start was called with correct params

**POST /internal/irc/connections without secret**
- POST without Authorization header
- Assert 401 unauthorized

**POST /internal/irc/connections with wrong secret**
- POST with incorrect Authorization header
- Assert 401 unauthorized

**DELETE /internal/irc/connections/:id**
- DELETE with valid secret
- Assert 200 ok
- Assert IrcConnectionManager.stop was called

### Controller: Internal::Irc::CommandsController

**POST /internal/irc/commands with active connection**
- Have active connection for server 1
- POST command
- Assert 202 accepted
- Assert command was queued

**POST /internal/irc/commands with no connection**
- No active connection
- POST command
- Assert 404 not found

### Controller: Internal::Irc::EventsController

**POST /internal/irc/events with connected event**
- POST connected event
- Assert server.connected_at is set

**POST /internal/irc/events with disconnected event**
- Have connected server
- POST disconnected event
- Assert server.connected_at is nil

**POST /internal/irc/events with message event**
- POST message event for channel
- Assert Message created with correct attributes

**POST /internal/irc/events with PM event**
- POST message event with non-channel target
- Assert Message created with target set
- Assert Notification created with reason "dm"

**POST /internal/irc/events with join event**
- POST join event
- Assert Channel found/created
- Assert ChannelUser created
- Assert Message created with type "join"

**POST /internal/irc/events with part event**
- Have channel with user
- POST part event
- Assert ChannelUser destroyed
- Assert Message created with type "part"

**POST /internal/irc/events switches tenant correctly**
- Have two users with servers
- POST event for user 1's server
- Assert changes in user 1's database only

### Controller: Internal::Irc::StatusController

**GET /internal/irc/status**
- Have some active connections
- GET with valid secret
- Assert JSON response with status and connections array

### Unit: InternalApiClient

**start_connection posts to IRC service**
- Stub HTTP
- Call start_connection
- Assert POST to correct URL with correct body

**send_command raises ConnectionNotFound on 404**
- Stub HTTP to return 404
- Call send_command
- Assert raises ConnectionNotFound

**send_command raises ServiceUnavailable on network error**
- Stub HTTP to raise error
- Call send_command
- Assert raises ServiceUnavailable

**post_event posts to web service**
- Stub HTTP
- Call post_event
- Assert POST to web service URL

## Implementation Notes

- Use `http` gem for HTTP client (add to Gemfile)
- All internal controllers skip CSRF verification
- Tenant context is switched in EventsController before handling
- IrcEventHandler is called within tenant context (see 07-messages-receive.md)
- In tests, POST directly to these endpoints to simulate IRC events

## Dependencies

- Requires `02-auth-multitenant.md` (tenant switching)
- Requires `03-server-crud.md` (Server model)
