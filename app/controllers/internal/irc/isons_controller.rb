module Internal
  module Irc
    class IsonsController < Internal::BaseController
      def show
        online_nicks = IrcConnectionManager.instance.ison(
          params[:server_id].to_i,
          params[:nicks]
        )

        if online_nicks
          render json: { online: online_nicks }
        else
          head :not_found
        end
      end
    end
  end
end
