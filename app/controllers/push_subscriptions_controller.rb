class PushSubscriptionsController < ApplicationController
  def create
    subscription = PushSubscription.find_or_initialize_by(endpoint: params.require(:endpoint))
    if subscription.update(user: Current.user, p256dh_key: key_params[:p256dh], auth_key: key_params[:auth])
      head :created
    else
      head :unprocessable_entity
    end
  end

  private

  def key_params
    params.require(:keys).permit(:p256dh, :auth)
  end
end
