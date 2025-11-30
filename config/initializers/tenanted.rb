Rails.application.configure do
  config.active_record_tenanted.connection_class = "TenantRecord"

  config.active_record_tenanted.tenant_resolver = ->(request) do
    if (session_id = request.cookie_jar.signed[:session_id])
      if (session = Session.find_by(id: session_id))
        session.user_id.to_s
      end
    end
  end
end
