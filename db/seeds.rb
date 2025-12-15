# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

if Rails.env.development?
  dev_user = User.find_or_create_by!(email_address: "dev@example.com") do |user|
    user.password = "Xk9#mP7$qR2@"
  end

  test_user = User.find_or_create_by!(email_address: "test@example.com") do |user|
    user.password = "123123"
  end

  Server.find_or_create_by!(user: dev_user, address: "localhost", port: 6667) do |server|
    server.nickname = "devuser"
    server.ssl = false
    server.ssl_verify = false
  end

  Server.find_or_create_by!(user: test_user, address: "localhost", port: 6667) do |server|
    server.nickname = "testuser"
    server.ssl = false
    server.ssl_verify = false
  end
end
