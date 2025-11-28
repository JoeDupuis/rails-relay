# User Sign In

## Description

Users sign in through a login form to access the application. Authentication is handled by Rails 8's built-in auth generator (`bin/rails generate authentication`).

A user who is not signed in cannot access any page except the login page. Attempting to access a protected page redirects to login.

After successful sign in, user is redirected to the root path.

## Behavior

### Login Form

- Located at `/session/new`
- Fields: email, password
- Submit button: "Sign in"

### Sign In Success

- Valid email + password → create session → redirect to root path
- Session stores reference to user

### Sign In Failure

- Invalid credentials → re-render form with error message
- Stay on `/session/new`
- Error message is generic: "Invalid email or password" (don't reveal which was wrong)

### Sign Out

- DELETE `/session` clears the session
- Redirects to login page

### Access Control

- All routes except `/session/*` require authentication
- Unauthenticated request → redirect to `/session/new`
- Store originally requested URL, redirect there after sign in

## Models

Uses User and Session models from Rails auth generator. See `docs/data-model.md`.

## Tests

### Controller: SessionsController

**GET /session/new**
- Renders login form
- Returns 200

**POST /session with valid credentials**
- Creates session record
- Redirects to root path (302)

**POST /session with invalid email**
- Returns 422
- Re-renders form
- Shows error message

**POST /session with invalid password**
- Returns 422
- Re-renders form
- Shows error message

**DELETE /session**
- Destroys session
- Redirects to /session/new

### Integration: Access Control

**Unauthenticated user visits protected page**
- GET /servers (or any protected route)
- Redirects to /session/new

**Authenticated user visits protected page**
- Sign in first
- GET /servers
- Returns 200 (not redirected)

**Redirect back after sign in**
- Unauthenticated user visits /servers
- Redirected to /session/new
- Signs in
- Redirected to /servers (not root)

## Implementation Notes

- Run `bin/rails generate authentication` to scaffold
- Generator creates User, Session, Current, and SessionsController
- Adjust generated code to match project conventions if needed
- Root path can be a placeholder for now (will be channel list later)
