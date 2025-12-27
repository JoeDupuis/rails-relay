# Rails Conventions

## General

- No trailing whitespace
- No comments in code
- Slim public interface - minimize exposed methods
- Private methods are truly private (use Ruby's `private` keyword)
- Avoid `Timeout` - especially in library code
- Never use `instance_variable_get`

## Models

### No Services Folder

DO NOT create a `services` folder or service objects. The `app/models/` folder is for business modelization, not just ActiveRecord models. Non-ActiveRecord classes (plain Ruby objects, domain concepts, etc.) belong in `app/models/`.

### Business Logic Lives Here

Models contain all business logic. Controllers should be thin - they only handle HTTP concerns.

```ruby
class Server < ApplicationRecord
  def connect!
    validate_can_connect!
    IrcProcess.spawn(self)
    update!(connected_at: Time.current)
  end

  private

  def validate_can_connect!
    raise AlreadyConnectedError if connected?
  end
end
```

### Validations

- Use built-in validators when possible
- Custom validations go in private methods
- Validate at the model level, not controller

### Callbacks

- Use sparingly
- Prefer explicit method calls over implicit callbacks
- `after_commit` for side effects (broadcasts, jobs)

### Associations

- Always specify `dependent:` option
- Use `has_many through:` over `has_and_belongs_to_many`

## Controllers

### 7 RESTful Actions Only

Controllers have exactly these actions and no others:
- `index`
- `show`
- `new`
- `create`
- `edit`
- `update`
- `destroy`

### No Custom Actions

If you need custom behavior, create a new resource:

```ruby
# Bad - custom action
class ServersController < ApplicationController
  def connect
    @server.connect!
  end
end

# Good - new resource
class Server::ConnectionsController < ApplicationController
  def create
    @server.connect!
  end

  def destroy
    @server.disconnect!
  end
end
```

### Strong Parameters

- Define in private method
- Only permit what you need

```ruby
private

def server_params
  params.require(:server).permit(:address, :port, :nickname)
end
```

### Before Actions

- Use for authentication, loading resources
- Keep simple - complex logic goes in models

## Views

### Partials

- Extract repeated markup into partials
- Use locals, not instance variables in partials
- Name partials with underscore prefix

### Helpers

- Keep view helpers simple
- Complex logic belongs in models or presenters

### Turbo

- Use Turbo Frames for partial page updates
- Use Turbo Streams for real-time updates
- Prefer morphing over replacing when possible

## Migrations

### Reversibility

- All migrations must be reversible
- Use `change` method when Rails can auto-reverse
- Use `up`/`down` when manual reversal needed

### Naming

- Use descriptive names: `add_nickname_to_servers`
- One concern per migration

## Testing

### Fixtures Over Factories

- Design fixtures as a realistic baseline world
- Tests should use fixtures as starting point
- Only create/modify in test when it's what the test is about

### Test Structure

```ruby
test "descriptive name of what is being tested" do
  # Given - setup (prefer fixtures)
  channel = channels(:ruby_channel)

  # When - action
  channel.mark_as_read!

  # Then - assertion
  assert_not channel.unread?
end
```

### Jobs in tests
You can call `perform_enqueued_jobs` (i prefer without the block) where relevant if a test needs the enqueued jobs to run.

### Authentication in Tests

Use `SessionTestHelper` for sign in/out. Do NOT create ad-hoc helpers or use manual POST to session_path.

```ruby
sign_in_as(user)
sign_out
```

Works in both integration/controller tests and system tests. No need to know passwords.

For system tests, call `visit` after `sign_in_as` since it only sets the cookie.

### Yaic / irc events
You can simulate events from yaic/irc servers by sending requests to the internal API directly.

### What to Test

- Public interface thoroughly
- Edge cases
- Error conditions
- Do not test private methods directly
