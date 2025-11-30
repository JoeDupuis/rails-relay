# Multi-Tenant Setup

## Description

Each user has their own isolated database. This keeps user data completely separate and allows for easy per-user backups/deletion.

We use the `activerecord-tenanted` gem from Basecamp.

The User and Session models live in the main (shared) database. All other models (Server, Channel, Message, etc.) live in per-user tenant databases.

## Behavior

### Tenant Activation

When a user signs in, their tenant database is activated for the duration of the request/session.

All queries to tenant models (Server, Channel, etc.) automatically scope to the user's database.

### Tenant Database Location

Tenant databases are SQLite files stored in:
```
storage/tenants/{user_id}.sqlite3
```

### Tenant Creation

When a user is created, their tenant database is automatically created and migrated.

### Accessing Tenant Models Without Auth

Background jobs and IRC processes need to access tenant data without a web session. They activate the tenant explicitly:

```ruby
Tenant.switch(user) do
  # All tenant model queries scoped to this user
  user_servers = Server.all
end
```

## Models

### Main Database (shared)
- User
- Session

### Tenant Database (per-user)
- Server
- Channel
- ChannelUser
- Message
- Notification

## Tests

### Unit: Tenant Isolation

**User A cannot see User B's servers**
- Create User A with a Server
- Create User B with a Server
- Switch to User A's tenant
- Query Server.all
- Assert only User A's server returned

**Tenant switch scopes queries**
- Create User A with Server "irc.libera.chat"
- Create User B with Server "irc.efnet.org"
- Switch to User A's tenant
- Assert Server.find_by(address: "irc.libera.chat") exists
- Assert Server.find_by(address: "irc.efnet.org") is nil

### Integration: Web Request Scoping

**Authenticated user only sees their data**
- Create User A, sign in as User A
- Create Server for User A via web
- Sign out, sign in as User B
- Visit servers index
- Assert User A's server not visible

## Implementation Notes

- Add `activerecord-tenanted` to Gemfile
- Configure tenant database path in initializer
- Create migrations for both main and tenant databases
- Main migrations: `db/migrate/`
- Tenant migrations: `db/tenant_migrate/` (or as gem specifies)
- See gem documentation for exact setup: https://github.com/basecamp/activerecord-tenanted

## Dependencies

- Requires `auth-signin.md` to be complete (needs User model)
