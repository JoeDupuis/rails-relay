# Move Services to Models Directory

## Description

Per project conventions (`.claude/rules/rails.md`), there should be NO `services` folder. The `app/models/` folder is for business modelization, not just ActiveRecord models. Non-ActiveRecord classes (plain Ruby objects, domain concepts, etc.) belong in `app/models/`.

Currently there is:
- `app/services/` with 4 files
- `test/services/` with 4 test files

These must be moved to `app/models/` and `test/models/` respectively.

## Files to Move

### Source: `app/services/`

```
app/services/
├── internal_api_client.rb
├── irc_connection.rb
├── irc_connection_manager.rb
└── irc_event_handler.rb
```

### Destination: `app/models/`

```
app/models/
├── internal_api_client.rb
├── irc_connection.rb
├── irc_connection_manager.rb
├── irc_event_handler.rb
└── ... (existing model files)
```

### Source: `test/services/`

```
test/services/
├── internal_api_client_test.rb
├── irc_connection_manager_test.rb
├── irc_connection_test.rb
└── irc_event_handler_test.rb
```

### Destination: `test/models/`

```
test/models/
├── internal_api_client_test.rb
├── irc_connection_manager_test.rb
├── irc_connection_test.rb
├── irc_event_handler_test.rb
└── ... (existing test files)
```

## Implementation

### Step 1: Move App Files

```bash
mv app/services/internal_api_client.rb app/models/
mv app/services/irc_connection.rb app/models/
mv app/services/irc_connection_manager.rb app/models/
mv app/services/irc_event_handler.rb app/models/
rmdir app/services
```

### Step 2: Move Test Files

```bash
mv test/services/internal_api_client_test.rb test/models/
mv test/services/irc_connection_manager_test.rb test/models/
mv test/services/irc_connection_test.rb test/models/
mv test/services/irc_event_handler_test.rb test/models/
rmdir test/services
```

### Step 3: Verify No References Break

These classes are already autoloaded by Rails via Zeitwerk. Moving them to `app/models/` should work identically since both directories are in the autoload paths.

Check for any explicit requires or path references that might break.

### Step 4: Run Tests

Run full test suite to verify nothing broke:
```bash
bin/rails test
```

### Step 5: Delete Empty Directories

Ensure `app/services/` and `test/services/` are deleted.

## Verification

After moving:
1. All tests pass
2. Application starts without errors
3. IRC connections work (connect to server, join channel, send message)
4. No `services` directories exist

## Tests

### Smoke Tests

**InternalApiClient still works**
- Given: Server exists and IRC service running
- When: InternalApiClient.send_command called
- Then: Command is sent successfully

**IrcConnection still works**
- Given: Server with valid credentials
- When: IrcConnection started
- Then: Connects to IRC server

**IrcEventHandler still works**
- Given: Event data from IRC
- When: IrcEventHandler.handle called
- Then: Event is processed correctly

**IrcConnectionManager still works**
- Given: Multiple servers
- When: Starting connections via manager
- Then: Connections are managed correctly

### Existing Tests Pass

All existing tests in the moved files should pass without modification (test file paths change but content stays the same).

## Implementation Notes

- No code changes needed, only file moves
- Rails autoloading handles both `app/services/` and `app/models/` identically
- If any file has `require` statements referencing old paths, update them
- Git will see these as renames if you use `git mv`

## Dependencies

None - this is a standalone refactoring that doesn't depend on other features.
