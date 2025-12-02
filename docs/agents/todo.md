- User list is not updating
- interface super glitchy
- channel list is empty even if I joined something
- support ssl no verify
- nick doesnt get updated
- Channels dont get rejoined (auto join feature)
- make INTERNAL_API_SECRET optional in dev
- no live update on other joining/leaving a channel
- No live update on connecting and no indication of anything going bad if it gets stuck
- reconnecting to a server I see that I am still in a channel even though I am not. We need to fix the sync with the backend client



- if a message fails to send we have no feedback.
- creating channel without # crash silently
- channel list not updated
- no auto connect


- Let's have the rails app check the status on the yaic process
- no timeout on disconnect/connect (or others)
- The channel show page doesn t refresh auto when joining
- the server channel list doesnt refresh auto when joining
- the connecting.. disconnecting... alert dont go away
- Now way to go to the channel view page
- if I kill the server it never disconects me:

Started POST "/internal/irc/events" for ::1 at 2025-12-01 22:25:17 -0800
Processing by Internal::Irc::EventsController#create as */*
  Parameters: {"server_id"=>2, "user_id"=>1, "event"=>{"type"=>"error", "message"=>"Broken pipe"}}
  User Load (0.1ms)  SELECT "users".* FROM "users" WHERE "users"."id" = 1 LIMIT 1 /*action='create',application='RailsRelay',controller='events'*/
  ↳ app/controllers/internal/irc/events_controller.rb:5:in `create'
  Server Load (0.1ms)  SELECT "servers".* FROM "servers" WHERE "servers"."user_id" = 1 AND "servers"."id" = 2 LIMIT 1 /*action='create',application='RailsRelay',controller='events'*/
  ↳ app/controllers/internal/irc/events_controller.rb:11:in `create'
Completed 200 OK in 2ms (ActiveRecord: 0.2ms (2 queries, 0 cached) | GC: 0.0ms)


IRC connection error: Broken pipe
<internal:io>:121:in `write_nonblock'
/Users/joedupuis/workspace/yaic/lib/yaic/socket.rb:78:in `block in write'
/Users/joedupuis/workspace/yaic/lib/yaic/socket.rb:71:in `synchronize'
/Users/joedupuis/workspace/yaic/lib/yaic/socket.rb:71:in `write'
/Users/joedupuis/workspace/yaic/lib/yaic/client.rb:178:in `privmsg'
/Users/joedupuis/workspace/rails_relay/app/services/irc_connection.rb:98:in `execute_command'
/Users/joedupuis/workspace/rails_relay/app/services/irc_connection.rb:87:in `process_commands'
/Users/joedupuis/workspace/rails_relay/app/services/irc_connection.rb:80:in `event_loop'
/Users/joedupuis/workspace/rails_relay/app/services/irc_connection.rb:41:in `run'
/Users/joedupuis/workspace/rails_relay/app/services/irc_connection.rb:15:in `block in start'
#<Thread:0x00000001233fd940 /Users/joedupuis/workspace/rails_relay/app/services/irc_connection.rb:15 run> terminated with exception (report_on_exception is true):
<internal:io>:121:in `write_nonblock': Broken pipe (Errno::EPIPE)
        from /Users/joedupuis/workspace/yaic/lib/yaic/socket.rb:78:in `block in write'
        from /Users/joedupuis/workspace/yaic/lib/yaic/socket.rb:71:in `synchronize'
        from /Users/joedupuis/workspace/yaic/lib/yaic/socket.rb:71:in `write'
        from /Users/joedupuis/workspace/yaic/lib/yaic/client.rb:209:in `quit'
        from /Users/joedupuis/workspace/rails_relay/app/services/irc_connection.rb:112:in `cleanup'
        from /Users/joedupuis/workspace/rails_relay/app/services/irc_connection.rb:46:in `run'
        from /Users/joedupuis/workspace/rails_relay/app/services/irc_connection.rb:15:in `block in start'
