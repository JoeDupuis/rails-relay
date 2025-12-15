# Fix File Uploads

## Description

File uploads are broken after the message form controller was simplified. Previously, file uploads went to `UploadsController` via JavaScript `fetch()`. Now the form just submits normally, so files go to `MessagesController` which doesn't handle them.

The fix: Move file upload logic from `UploadsController` into the `Message` model using `has_one_attached`, and update `MessagesController` to handle file attachments.

## Current State

**Message form (`messages/_form.html.erb`)**:
- Has file input with `data-action="change->message-form#submit"`
- Form submits to `channel_messages_path` or `conversation_messages_path`

**message_form_controller.js**:
- `submit()` calls `this.element.requestSubmit()`
- No special handling for files

**UploadsController**:
- Has file validation (allowed types, max size)
- Creates ActiveStorage blob
- Creates Message with URL as content
- Sends IRC command with URL

**Result**: Files get submitted to MessagesController which ignores them.

## Target State

**Message model**:
- `has_one_attached :file`
- File validation (types, size)
- Auto-generates URL content when file attached
- Handles sending to IRC

**MessagesController**:
- Accepts `file` param
- Attaches file to message if present
- Message model handles the rest

**UploadsController**:
- Can be deleted (or kept for API use)

## Behavior

### Sending a Message with File

1. User selects file in channel view
2. Form submits to MessagesController with file param
3. MessagesController creates Message with file attached
4. Message model:
   - Validates file type (PNG, JPEG, GIF, WebP)
   - Validates file size (max 10MB)
   - After save, generates blob URL and updates content
   - Sends IRC PRIVMSG with URL

### Validation Errors

- If file type invalid: render form with error
- If file too large: render form with error
- Use standard ActiveModel validations

### File Types Allowed

- `image/png`
- `image/jpeg`
- `image/gif`
- `image/webp`

### Maximum Size

- 10 megabytes

## Models

### Message

Add to existing model:

```ruby
class Message < ApplicationRecord
  has_one_attached :file

  validate :validate_file_type, if: -> { file.attached? }
  validate :validate_file_size, if: -> { file.attached? }

  after_create_commit :process_file_upload, if: -> { file.attached? }

  ALLOWED_FILE_TYPES = %w[image/png image/jpeg image/gif image/webp].freeze
  MAX_FILE_SIZE = 10.megabytes

  private

  def validate_file_type
    unless ALLOWED_FILE_TYPES.include?(file.content_type)
      errors.add(:file, "must be PNG, JPEG, GIF, or WebP")
    end
  end

  def validate_file_size
    if file.byte_size > MAX_FILE_SIZE
      errors.add(:file, "must be less than 10MB")
    end
  end

  def process_file_upload
    # Generate URL and update content
    # Send to IRC
  end
end
```

## Implementation

### Step 1: Add has_one_attached to Message

In `app/models/message.rb`:
- Add `has_one_attached :file`
- Add validation methods for type and size
- Add callback for processing upload after create

### Step 2: Update MessagesController

In `app/controllers/messages_controller.rb`:
- Add `:file` to permitted params
- Handle validation errors (re-render form)

### Step 3: Update Message Form

In `app/views/messages/_form.html.erb`:
- Ensure form has `multipart: true` (already has it)
- Ensure file input name is `message[file]` (currently just `file`)

### Step 4: Handle IRC Send

Move the InternalApiClient call from UploadsController to Message model:
- In `process_file_upload` callback
- Generate URL using `Rails.application.routes.url_helpers.rails_blob_url`
- Set message content to the URL
- Send PRIVMSG via InternalApiClient

### Step 5: Handle Errors Gracefully

When InternalApiClient fails:
- Don't fail the message creation
- Let the message exist with the file attached
- User can retry or see the URL

### Step 6: Delete or Keep UploadsController

Option A: Delete UploadsController entirely
Option B: Keep for direct API uploads (non-form submissions)

Recommend: Delete it. The Message model handles everything now.

## Tests

### Model Tests

**Message with valid file attachment**
- Given: Message with PNG file attached
- When: saved
- Then: message is valid and saved
- And: file is attached to message

**Message with invalid file type**
- Given: Message with PDF file attached
- When: validated
- Then: message has error on :file "must be PNG, JPEG, GIF, or WebP"

**Message with file too large**
- Given: Message with 15MB image attached
- When: validated
- Then: message has error on :file "must be less than 10MB"

**File upload generates URL in content**
- Given: Message with valid file attached
- When: saved
- Then: message.content contains blob URL

**File upload sends IRC command**
- Given: Message with file attached and channel
- When: saved
- Then: InternalApiClient.send_command called with PRIVMSG containing URL

### Controller Tests

**POST /channels/:id/messages with file**
- Given: logged in user, joined channel
- When: POST with file param
- Then: creates message with file attached
- And: redirects/turbo response

**POST /channels/:id/messages with invalid file type**
- Given: logged in user, joined channel
- When: POST with PDF file
- Then: returns 422
- And: renders form with error

**POST /channels/:id/messages with oversized file**
- Given: logged in user, joined channel
- When: POST with 15MB file
- Then: returns 422
- And: renders form with error

### Integration Tests

**Upload file flow**
1. User views channel
2. User selects image file
3. Form submits
4. Message created with file
5. URL appears in message list
6. IRC receives PRIVMSG with URL

## Implementation Notes

- Use `after_create_commit` not `after_save` to ensure file is persisted before generating URL
- The blob URL needs the host - use `Rails.application.routes.url_helpers.rails_blob_url(file, host: ...)`
- May need to pass host from controller via a class attribute or thread-local
- For IRC send failures, consider: create message anyway, just don't send to IRC
- File input name change: `name="file"` → `name="message[file]"` to fit Rails conventions

## Dependencies

None - this is a standalone fix.
