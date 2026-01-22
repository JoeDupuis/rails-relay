class ConfigurationsController < ApplicationController
  allow_unauthenticated_access

  def android_v1
    render json: {
      settings: {},
      rules: [
        {
          patterns: [ "/rails/active_storage/" ],
          properties: {
          }
        },
        {
          patterns: [ ".*" ],
          properties: {
            context: "default",
            uri: "hotwire://fragment/web",
            pull_to_refresh_enabled: true
          }
        },
        {
          patterns: [ "^$", "^/$" ],
          properties: {
            presentation: "clear_all"
          }
        },
        {
          patterns: [ "/new$", "/edit$" ],
          properties: {
            context: "modal",
            pull_to_refresh_enabled: false
          }
        }
      ]
    }
  end
end
