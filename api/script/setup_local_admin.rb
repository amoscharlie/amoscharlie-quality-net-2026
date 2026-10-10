abort 'Local development only' unless Rails.env.development?
password = ENV.fetch('LOCAL_ADMIN_PASSWORD')
abort 'Use a password with at least 16 characters' if password.length < 16
organization = Organization.find_by!(scheme: ENV.fetch('LOCAL_TENANT_SCHEME', 'test-corp'))
user = User.find_or_initialize_by(email: ENV.fetch('LOCAL_ADMIN_EMAIL', 'owner@example.test'))
user.update!(password: password, role: 'admin', tenant_id: organization.id)
puts 'Local admin provisioned with server-owned organization membership.'
