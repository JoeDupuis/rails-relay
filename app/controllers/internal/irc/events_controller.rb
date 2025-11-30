module Internal
  module Irc
    class EventsController < Internal::BaseController
      def create
        user = User.find(params[:user_id])
        server_id = params[:server_id]
        event = params[:event]

        Current.user_id = user.id

        Tenant.switch(user) do
          server = Server.find(server_id)
          IrcEventHandler.handle(server, event)
        end

        head :ok
      end
    end
  end
end
