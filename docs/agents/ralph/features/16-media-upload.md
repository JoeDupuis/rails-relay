# Media Upload

## Description

Users can upload images which are stored via ActiveStorage. A URL to the image is sent to the IRC channel.

## Behavior

### Upload Flow

1. User clicks upload button (or pastes/drops image)
2. File uploaded to server via ActiveStorage
3. Server generates a public URL for the file
4. URL is sent as a message to the current channel
5. Message appears in chat with the URL

### Supported File Types

For MVP:
- Images: jpg, jpeg, png, gif, webp

Later:
- Other files (pdf, txt, etc.)

### Upload UI

Options:
- Upload button next to message input
- Drag and drop onto message area
- Paste from clipboard (Ctrl+V)

For MVP: Upload button is sufficient.

### URL Format

ActiveStorage generates URLs like:
```
https://yourapp.com/rails/active_storage/blobs/redirect/eyJfcmFpbHMiOns.../filename.png
```

Or with a custom subdomain/path:
```
https://yourapp.com/uploads/abc123/image.png
```

The URL should:
- Be publicly accessible (no auth required) for IRC users to view
- Not be guessable/enumerable (random token in path)
- Not expire (or have long expiry)

### File Size Limit

- Max file size: 10MB (configurable)
- Reject files over limit with error message

### Storage Location

ActiveStorage defaults:
- Development: local disk (`storage/`)
- Production: configurable (local, S3, etc.)

For MVP: local storage is fine.

## Models

### Upload

Could be a separate model, or just use ActiveStorage directly.

Option 1: Direct attachment on Message (complex - message already exists before upload)

Option 2: Separate Upload model:

```ruby
# app/models/upload.rb
class Upload < ApplicationRecord
  belongs_to :server
  belongs_to :channel, optional: true
  
  has_one_attached :file
  
  validates :file, attached: true, 
    content_type: ['image/png', 'image/jpeg', 'image/gif', 'image/webp'],
    size: { less_than: 10.megabytes }
  
  def public_url
    Rails.application.routes.url_helpers.rails_blob_url(file, only_path: false)
  end
end
```

But we said there's no DB reference between message and upload - the message just contains the URL as text. So maybe we don't need an Upload model at all, just handle the ActiveStorage blob directly.

Simpler approach:

```ruby
# In controller, just create a blob and get its URL
blob = ActiveStorage::Blob.create_and_upload!(
  io: params[:file],
  filename: params[:file].original_filename,
  content_type: params[:file].content_type
)
url = rails_blob_url(blob)
# Then send url as message
```

## Controller

```ruby
# app/controllers/uploads_controller.rb
class UploadsController < ApplicationController
  def create
    @channel = Channel.find(params[:channel_id])
    @server = @channel.server
    
    file = params[:file]
    
    # Validate
    unless valid_file?(file)
      render json: { error: "Invalid file type or size" }, status: :unprocessable_entity
      return
    end
    
    # Upload to ActiveStorage
    blob = ActiveStorage::Blob.create_and_upload!(
      io: file,
      filename: file.original_filename,
      content_type: file.content_type
    )
    
    # Generate URL
    url = rails_blob_url(blob, host: request.base_url)

    # Create local message record
    @message = Message.create!(
      server: @server,
      channel: @channel,
      sender: @server.nickname,
      content: url,
      message_type: "privmsg"
    )

    # Send as message to channel via internal API
    InternalApiClient.send_command(
      server_id: @server.id,
      command: "privmsg",
      params: { target: @channel.name, message: url }
    )

    respond_to do |format|
      format.turbo_stream
      format.json { render json: { url: url, message_id: @message.id } }
    end
  rescue InternalApiClient::ConnectionNotFound, InternalApiClient::ServiceUnavailable => e
    render json: { error: e.message }, status: :service_unavailable
  end
  
  private
  
  ALLOWED_TYPES = %w[image/png image/jpeg image/gif image/webp].freeze
  MAX_SIZE = 10.megabytes
  
  def valid_file?(file)
    return false unless file.present?
    return false unless ALLOWED_TYPES.include?(file.content_type)
    return false if file.size > MAX_SIZE
    true
  end
end
```

## Routes

```ruby
resources :channels do
  resources :uploads, only: [:create]
end
```

## ActiveStorage Configuration

```ruby
# config/storage.yml
local:
  service: Disk
  root: <%= Rails.root.join("storage") %>

# For production, consider S3:
# amazon:
#   service: S3
#   bucket: your-bucket
#   ...
```

```ruby
# config/environments/development.rb
config.active_storage.service = :local

# For public URLs without auth
config.active_storage.resolve_model_to_route = :rails_storage_proxy
```

### Making Blobs Public

By default, ActiveStorage URLs require a redirect through Rails. For truly public URLs that work even when your app is down:

```ruby
# config/initializers/active_storage.rb
Rails.application.config.active_storage.service_urls_expire_in = 1.year
```

Or use `rails_storage_proxy` which serves the file directly.

For IRC, the URL just needs to be accessible. The redirect approach works fine.

## View

Upload button in message form:

```erb
<%# app/views/messages/_form.html.erb %>
<%= form_with url: channel_messages_path(channel), 
    class: "message-input",
    data: { controller: "message-form" } do |f| %>
  
  <%= f.text_field :content, placeholder: "Message #{channel.name}", class: "field" %>
  
  <label class="upload">
    📎
    <input type="file" 
           accept="image/*"
           data-action="change->message-form#upload"
           data-message-form-target="fileInput"
           hidden>
  </label>
  
  <%= f.submit "Send", class: "submit" %>
<% end %>
```

## Stimulus Controller

```javascript
// app/javascript/controllers/message_form_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "fileInput"]
  static values = { uploadUrl: String }
  
  upload(event) {
    const file = event.target.files[0]
    if (!file) return
    
    const formData = new FormData()
    formData.append("file", file)
    
    // Show uploading indicator
    this.inputTarget.placeholder = "Uploading..."
    this.inputTarget.disabled = true
    
    fetch(this.uploadUrlValue, {
      method: "POST",
      body: formData,
      headers: {
        "X-CSRF-Token": document.querySelector("[name='csrf-token']").content
      }
    })
    .then(response => response.json())
    .then(data => {
      // Message is created server-side, will appear via Turbo Stream
      this.inputTarget.placeholder = `Message ${this.channelName}`
      this.inputTarget.disabled = false
    })
    .catch(error => {
      alert("Upload failed")
      this.inputTarget.placeholder = `Message ${this.channelName}`
      this.inputTarget.disabled = false
    })
    
    // Clear file input
    event.target.value = ""
  }
}
```

## Tests

### Controller: UploadsController#create

**POST with valid image**
- Upload PNG file
- Returns 200/success
- Blob created in ActiveStorage
- Message created with URL
- IRC command sent

**POST with invalid file type**
- Upload PDF
- Returns 422
- No blob created
- No message sent

**POST with file too large**
- Upload 15MB image
- Returns 422
- No blob created

### Integration: Upload Flow

**User uploads image**
- View channel
- Click upload button
- Select image file
- Image uploads
- URL message appears in chat

### Model/Blob

**Generated URL is accessible**
- Create blob
- Get URL
- Fetch URL
- Returns the image

**URL is not guessable**
- Create two blobs
- URLs are different
- Can't predict one from the other

## Implementation Notes

- ActiveStorage handles secure random tokens in URLs
- Consider adding image preview before sending
- Consider progress indicator for large uploads
- For paste support, listen for paste event and check for image data
- Drag and drop: listen for dragover/drop events on message area
- May want to store upload references for admin/moderation purposes later

## Dependencies

- Requires `06-channels.md` (channel context)
- Requires `08-messages-send.md` (sending the URL message)
- Requires `04-internal-api.md` (InternalApiClient)
