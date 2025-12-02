Rails.application.config.after_initialize do
  next if Rails.env.test?

  ConnectionHealthCheckJob.perform_later
end
