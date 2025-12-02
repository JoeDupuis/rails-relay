# List Public Channels

## Description

Add ability to see all public channels available on an IRC server using the LIST command, and join them from the list.

## Behavior

### UI

Add a "Browse Channels" section/button on the server show page that:
1. Triggers a LIST command to the IRC server
2. Displays results in a modal or expandable section
3. Each channel shows: name, user count, topic
4. Each channel has a "Join" button

### IRC LIST Command

The IRC LIST command returns channel information. The response comes as multiple RPL_LIST (322) messages followed by RPL_LISTEND (323).

Format of RPL_LIST:
```
:server 322 yournick #channel usercount :topic
```

### IrcConnection

Add handler for LIST command:
```ruby
when "list"
  @client.raw("LIST")
```

Add yaic event listener for list results. If yaic doesn't have a `:list` event, we need to handle the raw 322/323 numerics.

**Check yaic first**: Look at `Yaic::Client#handle_message` and `emit_events` to see if list is supported. If not, this may require yaic changes.

### IrcEventHandler

Handle list events by collecting results and broadcasting when complete:
```ruby
when "list_start"
  # Initialize list collection for this server
when "list_item"
  # Add channel to collection
when "list_end"
  # Broadcast complete list to server stream
```

### Views

Add to server show page:
```erb
<section class="channel-browser">
  <h2>Browse Channels</h2>
  <%= button_to "Load Channels", server_channel_list_path(@server), method: :post, class: "button" %>

  <div id="<%= dom_id(@server, :channel_list) %>">
    <!-- Populated via Turbo Stream when list loads -->
  </div>
</section>
```

Create `servers/_channel_list.html.erb`:
```erb
<div id="<%= dom_id(server, :channel_list) %>">
  <% if channels.any? %>
    <table class="channel-list">
      <thead>
        <tr>
          <th>Channel</th>
          <th>Users</th>
          <th>Topic</th>
          <th></th>
        </tr>
      </thead>
      <tbody>
        <% channels.each do |channel| %>
          <tr>
            <td><%= channel[:name] %></td>
            <td><%= channel[:users] %></td>
            <td><%= truncate(channel[:topic], length: 100) %></td>
            <td>
              <%= form_with url: server_channels_path(server) do |f| %>
                <%= f.hidden_field :name, name: "channel[name]", value: channel[:name] %>
                <%= f.submit "Join", class: "link" %>
              <% end %>
            </td>
          </tr>
        <% end %>
      </tbody>
    </table>
  <% else %>
    <p>No public channels found.</p>
  <% end %>
</div>
```

## Routes

```ruby
resource :channel_list, only: [:create], controller: "server/channel_lists"
```

## Controller

Create `Server::ChannelListsController`:
```ruby
class Server::ChannelListsController < ApplicationController
  before_action :set_server

  def create
    InternalApiClient.send_command(
      server_id: @server.id,
      command: "list",
      params: {}
    )
    head :ok
  rescue InternalApiClient::ServiceUnavailable
    render turbo_stream: turbo_stream.replace(
      dom_id(@server, :channel_list),
      html: "<p class='error'>IRC service unavailable</p>"
    )
  rescue InternalApiClient::ConnectionNotFound
    render turbo_stream: turbo_stream.replace(
      dom_id(@server, :channel_list),
      html: "<p class='error'>Server not connected</p>"
    )
  end

  private

  def set_server
    @server = Current.user.servers.find(params[:server_id])
  end
end
```

## Models

No persistent storage for channel list - it's ephemeral and displayed via Turbo Stream.

## Tests

### Controller Tests

**POST channel_list sends list command**
- Given: Connected server
- When: POST /servers/:id/channel_list
- Then: InternalApiClient.send_command called with command: "list"

**POST channel_list handles service unavailable**
- Given: InternalApiClient raises ServiceUnavailable
- When: POST /servers/:id/channel_list
- Then: Error message returned in Turbo Stream

### Integration Tests

**Channel list displayed after LIST completes**
- Given: User on server page, clicks "Load Channels"
- When: IrcEventHandler receives list_end event with channels
- Then: Channel list table is displayed with channel names

**Join from channel list works**
- Given: Channel list showing #ruby
- When: User clicks "Join" next to #ruby
- Then: Join command sent, channel joined

## Implementation Notes

**IMPORTANT**: First check if yaic supports LIST:
1. Look for `:list` event in yaic client
2. Look for handling of 322/323 numerics
3. If not supported, use `AskUserQuestion` to pause: "The yaic gem doesn't support LIST command events. Need to add support for 322/323 numerics in yaic."

If yaic needs changes, this feature should be deferred until yaic is updated.

## Dependencies

- May depend on yaic gem changes if LIST is not supported
