require 'rails_helper'
RSpec.describe 'Login organization authority', type: :request do
 it 'A15 cannot mint an organization credential from a client supplied scheme without membership' do
  organization('login-owner'); target=organization('login-other')
  User.create!(email:'local-admin@example.test',password:'test-password-long',role:'admin')
  post '/api/v1/auth/login',params:{email:'local-admin@example.test',password:'test-password-long'},headers:{'X-Tenant-Scheme'=>target.scheme}
  expect(response).to have_http_status(:unauthorized)
  expect(response.body).not_to include('token')
 end
end
