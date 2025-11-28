# Agent Prompt

You are implementing an IRC client Rails application, feature by feature.

## Configuration

```
EXIT_SCRIPT: __EXIT_SCRIPT_PATH__
QA_AGENT: __QA_AGENT_NAME__
```

## Getting Your Bearings

At the start of each session:

1. Read `.claude/ralph/progress.md` for recent context and hints
2. Run `git log --oneline -10` to see recent work
3. List `.claude/ralph/features/` to see available features
4. Pick a feature (files ending in `.md`, not `.md.done`)

The progress file often has a "suggested next feature" from the previous session. Start there unless you have reason to do otherwise.

## Working on a Feature

1. Read the feature file completely
2. Read any referenced docs (data model, conventions)
3. Write or verify tests exist for the acceptance criteria
4. Implement until tests pass
5. Run `bin/ci` to verify everything passes
6. Call the QA agent: `__QA_AGENT_NAME__`
7. If QA passes, wrap up (see below)
8. If QA has issues, fix them and repeat

## Running Things

```bash
# Start the app
bin/dev

# Run all tests
bin/ci

# Run specific test file
bin/rails test test/controllers/servers_controller_test.rb

# Run specific test
bin/rails test test/controllers/servers_controller_test.rb -n "test_name"
```

## IRC Test Server

Tests require a running IRC server. Check status / start / stop:

```bash
__IRC_SERVER_STATUS_SCRIPT__
__IRC_SERVER_START_SCRIPT__
__IRC_SERVER_STOP_SCRIPT__
```

Server: `localhost:__IRC_SERVER_PORT__` (SSL: `__IRC_SERVER_SSL__`)

### Parallel Test Isolation

Rails runs tests in parallel. Use `TEST_ENV_NUMBER` to namespace IRC resources and prevent clashes between workers.

In fixtures, use ERB:
```yaml
# channels.yml
ruby_channel:
  server: main_server
  name: "#w<%= ENV['TEST_ENV_NUMBER'] || '0' %>-ruby"
```

Helpers available in tests:
```ruby
def parallel_worker_id
  ENV["TEST_ENV_NUMBER"].presence || "0"
end

def test_channel(name)
  "#w#{parallel_worker_id}-#{name}"
end

def test_nick(name)
  "#{name}_w#{parallel_worker_id}"
end
```

### Fixtures Philosophy

Prefer fixtures over factory creation. Design a semi-realistic world in fixtures that covers most test scenarios. 

When writing tests:
- Use fixtures as the baseline
- Only create/modify models in the test when it demonstrates what the test is about
- Minimal setup in tests - if you need complex setup repeatedly, it probably belongs in fixtures

Good:
```ruby
test "unread count increases when message received" do
  channel = channels(:ruby_channel)
  assert_difference -> { channel.reload.unread_count } do
    Message.create!(channel: channel, content: "new message", ...)
  end
end
```

The `Message.create!` is the point - it shows what triggers the behavior.

## Asking Questions

If you encounter:
- Unclear requirements
- Conflicting information
- Something that seems wrong
- A decision that needs human input

Use the `AskUserQuestion` tool. Explain the situation clearly and wait for guidance.

Do NOT guess at requirements. Ask.

## When You Think a Different Feature Should Be Next

If while working you realize a different feature should come first:
1. Use `AskUserQuestion` to explain your reasoning
2. If approved, write your findings to `progress.md`
3. Exit without completing current feature

## Wrapping Up a Feature

When the feature is complete and QA passes:

1. **Rename the feature file**
   ```bash
   mv .claude/ralph/features/feature-name.md .claude/ralph/features/feature-name.md.done
   ```

2. **Update progress.md**
   Append a section with:
   - What was completed
   - Any notes for future sessions
   - Suggested next feature

3. **Commit**
   ```bash
   git add -A
   git commit -m "feat: [description]
   
   - Completed: [feature name]
   - Tests: [what tests were added]"
   ```

4. **Exit**
   Call the exit script to end this session:
   ```bash
   __EXIT_SCRIPT_PATH__
   ```

## Important Rules

### DO NOT exit until the feature is complete
The exit script ends the session. Only call it after:
- Feature is implemented
- Tests pass
- QA agent approves
- Progress file is updated
- Changes are committed

### DO NOT change tests without approval
Tests define the contract. If you think a test is wrong:
1. Use `AskUserQuestion` to explain why
2. Wait for approval before changing
3. Document the change in your commit

### DO NOT skip or re-fail passing tests
Tests may start skipped or failing. Once a test passes, it must stay passing. Do not:
- Add `skip` to a previously passing test
- Make changes that cause a passing test to fail
- Comment out assertions

If a passing test starts failing:
1. Investigate why
2. Fix the code, not the test
3. If the test is wrong, ask for approval to change it

## Conventions

Code must follow project conventions:

- **Rails**: See `docs/conventions/rails.md`
  - Business logic in models
  - Controllers: 7 RESTful actions only, no custom actions
  - Need custom behavior? Create a new resource

- **CSS**: See `docs/conventions/rscss.md`  
  - Components: two-word names (`.message-item`)
  - Elements: single word with `>` (`.message-item > .content`)
  - Variants: dash prefix (`.-unread`)
  - Component-scoped variables, minimal globals

## File Locations

```
.claude/ralph/
├── prompt.md          # This file
├── progress.md        # Session history and hints
└── features/          # Feature specs
    ├── feature.md     # Not started or in progress
    └── feature.md.done # Completed

docs/
├── data-model.md      # Database schema
└── conventions/
    ├── rails.md
    └── rscss.md
```
