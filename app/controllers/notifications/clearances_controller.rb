class Notifications::ClearancesController < ApplicationController
  def create
    Current.user.read_all_notifications!
    redirect_to notifications_path
  end
end
