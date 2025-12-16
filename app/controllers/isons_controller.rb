class IsonsController < ApplicationController
  def show
    conversations_by_server = Current.user.servers
      .where(connected_at: ..Time.current)
      .includes(:conversations)
      .flat_map { |server| server.conversations.open }
      .group_by(&:server_id)

    conversations_by_server.each do |server_id, conversations|
      nicks = conversations.map(&:target_nick)
      online_nicks = InternalApiClient.ison(server_id: server_id, nicks: nicks) || []
      online_nicks_downcased = online_nicks.map(&:downcase)

      conversations.each do |conversation|
        conversation.update_column(:online, online_nicks_downcased.include?(conversation.target_nick.downcase))
      end
    end

    @conversations = conversations_by_server.values.flatten
  end
end
