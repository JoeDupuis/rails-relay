Rails.application.config.to_prepare do
  irc_threads = Thread.list.select { |t| t.name&.start_with?("rails_relay_irc_") }
  next if irc_threads.empty?

  server_ids = irc_threads.filter_map do |thread|
    thread.name.delete_prefix("rails_relay_irc_").to_i
  end

  irc_threads.each(&:kill)

  Thread.new do
    irc_threads.each { |t| t.join(5) }

    Server.where(id: server_ids).find_each do |server|
      IrcConnectionManager.instance.start(
        server_id: server.id,
        user_id: server.user_id,
        config: server.connection_config
      )
    rescue => e
      Rails.logger.error "IRC reconnect failed for server #{server.id}: #{e.message}"
    end
  end
end
