require 'rails_helper'
RSpec.describe 'Login organization authority', type: :request do
 it 'A15 cannot mint an organization credential from a client supplied scheme without membership' do
  organization('login-owner'); target=organization('login-other')
  User.create!(email:'local-admin@example.test',password:'test-password-long',role:'admin')
  post '/api/v1/auth/login',params:{email:'local-admin@example.test',password:'test-password-long'},headers:{'X-Tenant-Scheme'=>target.scheme}
  expect(response).to have_http_status(:unauthorized)
  expect(response.body).not_to include('token')
 end
 it 'allows bound admin login using only the server-owned organization' do
  owner=organization('login-bound')
  User.create!(tenant_id:owner.id,email:'bound@example.test',password:'test-password-long',role:'admin')
  post '/api/v1/auth/login',params:{email:'bound@example.test',password:'test-password-long'}
  expect(response).to have_http_status(:ok)
  payload=JSON.parse(response.body);token=payload.fetch('token')
  expect(JsonWebToken.decode(token)[:scheme]).to eq(owner.scheme)
 end
 it 'rejects even a bound admin when the requested organization differs' do
  owner=organization('bound-owner');other=organization('bound-other')
  User.create!(tenant_id:owner.id,email:'bound@example.test',password:'test-password-long',role:'admin')
  post '/api/v1/auth/login',params:{email:'bound@example.test',password:'test-password-long'},headers:{'X-Tenant-Scheme'=>other.scheme}
  expect(response).to have_http_status(:unauthorized)
 end

end
