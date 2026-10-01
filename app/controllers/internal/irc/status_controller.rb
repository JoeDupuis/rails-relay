module Internal
  module Irc
    class StatusController < Internal::BaseController
      def show
        render json: {
          status: "ok",
          connections: IrcConnectionManager.instance.active_connections,
          connected: IrcConnectionManager.instance.connected_connections
        }
      end
    end
  end
end
