module Internal
  module Irc
    class CommandsController < Internal::BaseController
      def create
        result = IrcConnectionManager.instance.send_command(
          params[:server_id].to_i,
          params[:command],
          params[:params]&.to_unsafe_h&.symbolize_keys || {}
        )

        if result
          render json: { parts: result }, status: :accepted
        else
          head :not_found
        end
      end
    end
  end
end
