Rails.application.config.after_initialize do
  next if Rails.env.test?
  next if ENV["SECRET_KEY_BASE_DUMMY"]

  ConnectionHealthCheckJob.perform_later
rescue ActiveRecord::StatementInvalid, SolidQueue::Job::EnqueueError
end
