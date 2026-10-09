class Notifications::ClearancesController < ApplicationController
  def create
    Notification.for_user(Current.user).mark_all_as_read!
    redirect_to notifications_path
  end
end
