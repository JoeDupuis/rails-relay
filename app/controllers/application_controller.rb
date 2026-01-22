class ApplicationController < ActionController::Base
  include Authentication
  allow_browser versions: :modern
  stale_when_importmap_changes
  before_action :disable_cloudflare_scrape_shield

  private

  def disable_cloudflare_scrape_shield
    response.headers["X-CF-Data-Scraping-Protection"] = "off"
  end
end
