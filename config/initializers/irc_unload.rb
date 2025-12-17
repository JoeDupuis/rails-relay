Rails.application.config.to_prepare do
  Thread.list.each do |thread|
    if thread.name&.start_with?("rails_relay_irc_")
      thread.kill
    end
  end
end
