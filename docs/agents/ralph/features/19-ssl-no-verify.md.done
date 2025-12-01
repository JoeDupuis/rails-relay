# SSL No-Verify Option

## Description

Add a per-server option to skip SSL certificate verification. This is useful for connecting to IRC servers with self-signed certificates or internal servers.

## Behavior

### Server Form
- Add a checkbox field "Verify SSL certificate" (default: checked/true)
- Only visible/relevant when SSL is enabled
- When unchecked, the connection will not verify the server's SSL certificate

### Database
- Add `ssl_verify` boolean column to servers table (default: true)

### IRC Connection
- Pass the `ssl_verify` setting to the yaic client
- When `ssl_verify` is false, disable certificate verification

## Models

### Server

Add field:
| Field | Type | Notes |
|-------|------|-------|
| ssl_verify | boolean | Default true, whether to verify SSL cert |

## UI

### Server Form

The SSL verify checkbox should:
- Appear below the SSL checkbox
- Only be enabled when SSL is checked
- Use JavaScript to disable/enable based on SSL checkbox state
- Default to checked (verify certificates)

Example layout:
```
[ ] SSL
    [ ] Verify SSL certificate
```

When SSL is unchecked, the verify checkbox should be disabled and hidden.

## Tests

### Model Tests

**ssl_verify defaults to true**
- Given: A new server
- When: No ssl_verify value is set
- Then: ssl_verify is true

**ssl_verify can be set to false**
- Given: A server with ssl: true, ssl_verify: false
- When: Saved
- Then: ssl_verify persists as false

### Controller Tests

**create accepts ssl_verify param**
- Given: Valid server params with ssl_verify: false
- When: POST to create
- Then: Server is created with ssl_verify: false

**update accepts ssl_verify param**
- Given: Existing server
- When: PATCH with ssl_verify: false
- Then: Server ssl_verify is updated to false

### Integration Tests

**Server form shows SSL verify option**
- Given: User is on new server page
- When: SSL checkbox is checked
- Then: SSL verify checkbox is visible and checked by default

**SSL verify checkbox follows SSL checkbox**
- Given: User is on new server page
- When: User unchecks SSL
- Then: SSL verify checkbox is disabled/hidden

## Implementation Notes

1. Generate migration: `rails g migration AddSslVerifyToServers ssl_verify:boolean`
   - Set default to true in migration

2. Update Server model:
   - Add `ssl_verify` to defaults in `set_defaults` if nil
   - No validation needed (boolean with default)

3. Update `server_params` in ServersController to permit `:ssl_verify`

4. Update server form partial:
   - Add checkbox for ssl_verify
   - Update the existing Stimulus controller (auth_method_controller) or create new one for SSL toggle

5. Update IrcConnection to pass ssl_verify to yaic:
   - Check yaic gem docs for how to disable SSL verification
   - May need to pass `ssl_verify: false` or similar option

6. Update InternalApiClient if it passes SSL config

## Dependencies

- May require changes to yaic gem if it doesn't support ssl_verify option
