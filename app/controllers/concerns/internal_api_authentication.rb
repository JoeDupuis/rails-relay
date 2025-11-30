module InternalApiAuthentication
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_internal_api!
  end

  private

  def authenticate_internal_api!
    expected = ENV.fetch("INTERNAL_API_SECRET")
    provided = request.headers["Authorization"]&.delete_prefix("Bearer ")

    head :unauthorized unless ActiveSupport::SecurityUtils.secure_compare(expected.to_s, provided.to_s)
  end
end
