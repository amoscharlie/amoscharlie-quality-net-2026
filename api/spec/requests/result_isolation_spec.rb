require 'rails_helper'
RSpec.describe 'Result ownership boundary', type: :request do
  let!(:owner) { organization('owner') }
  let!(:other) { organization('other') }
  let!(:session) { session_for(owner) }
  let!(:portfolio) { session.create_portfolio!(generation_status: 'complete') }
  let!(:skill) { skill_for(portfolio) }
  it 'A01 denies cross-tenant JSON export' do
    get "/api/v1/portfolios/#{portfolio.id}/export", headers: auth(other)
    expect(response).to have_http_status(:not_found)
    expect(response.body).not_to include('Measured trade-offs')
  end
  it 'A01 denies cross-tenant mutation without changing stored override' do
    post "/api/v1/portfolio_skills/#{skill.id}/override", params: {override: {override_level: 5}}, headers: auth(other), as: :json
    expect(response).to have_http_status(:not_found)
    expect(skill.reload.assessor_override).to be_nil
  end
  it 'allows owner export and preserves the stored level' do
    get "/api/v1/portfolios/#{portfolio.id}/export", headers: auth(owner)
    expect(response).to have_http_status(:ok)
    expect(JSON.parse(response.body).dig('portfolio', 'skills', 0, 'ai_level')).to eq(3)
  end
  it 'A01 denies cross-tenant fit/gap creation' do
    vacancy = Current.using(tenant_id: other.id) { Vacancy.create!(role_title: 'Engineer', created_by: 1) }
    post "/api/v1/portfolios/#{portfolio.id}/fitgap", params: {vacancy_id: vacancy.id}, headers: auth(other), as: :json
    expect(response).to have_http_status(:not_found)
    expect(FitGapGeneratorWorker.jobs).to be_empty
  end
  it 'A09 denies a non-assessor coverage subscriber' do
    token = JsonWebToken.encode(user_id: 1, role: 'user', scheme: owner.scheme)
    found, error = CoverageWebSocketMiddleware.new(->(_) {}).send(:authenticate_assessor_by_token, token, session.id)
    expect(found).to be_nil
    expect(error).to be_present
  end
end
