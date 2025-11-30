module Internal
  module Irc
    class ConnectionsController < Internal::BaseController
      def create
        IrcConnectionManager.instance.start(
          server_id: params[:server_id],
          user_id: params[:user_id],
          config: params[:config].to_unsafe_h.symbolize_keys
        )
        head :accepted
      end

      def destroy
        IrcConnectionManager.instance.stop(params[:id].to_i)
        head :ok
      end
    end
  end
end
