module Internal
  class BaseController < ActionController::Base
    include InternalApiAuthentication
    skip_before_action :verify_authenticity_token
  end
end
