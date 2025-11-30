workers 0
threads 1, 1

port ENV.fetch("IRC_SERVICE_PORT", 3001)

environment ENV.fetch("RAILS_ENV", "production")
