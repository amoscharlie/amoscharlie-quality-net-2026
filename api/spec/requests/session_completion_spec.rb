require 'rails_helper'
RSpec.describe 'Candidate completion boundary', type: :request do
  let!(:org) { organization('completion') }
  it 'A02 rejects completion before the interview started' do
    session = session_for(org, status: 'pending')
    post "/api/v1/sessions/#{session.invite_token}/audio_complete"
    expect(response).to have_http_status(:unprocessable_entity)
    expect(session.reload.status).to eq('pending')
    expect(session.portfolio).to be_nil
  end
  it 'A02 rejects an active session with uncovered skills' do
    session = session_for(org)
    session.coverage_maps.create!(skill_id: 'SK-ENG-001', skill_label: 'Frontend', state: 'partial', probe_count: 2)
    post "/api/v1/sessions/#{session.invite_token}/audio_complete"
    expect(response).to have_http_status(:unprocessable_entity)
    expect(session.reload.status).to eq('active')
    expect(PortfolioGeneratorWorker.jobs).to be_empty
  end
  it 'ends covered sessions once, preserving duration and a single portfolio' do
    session = session_for(org)
    session.coverage_maps.create!(skill_id: 'SK-ENG-001', skill_label: 'Frontend', state: 'covered', probe_count: 3)
    2.times { post "/api/v1/sessions/#{session.invite_token}/audio_complete"; expect(response).to have_http_status(:ok) }
    expect(session.reload.end_reason).to eq('all_covered')
    expect(session.duration_seconds).to be >= 0
    expect(Portfolio.where(session_id: session.id).count).to eq(1)
    expect(PortfolioGeneratorWorker.jobs.size).to eq(1)
  end
  it 'A07 candidate recovery info preserves the persisted failure reason' do
    session = session_for(organization('failed-info'),status:'ended')
    session.update!(end_reason:'error')
    get "/api/v1/sessions/#{session.invite_token}/candidate"
    expect(response).to have_http_status(:ok)
    expect(JSON.parse(response.body).fetch('end_reason')).to eq('error')
  end

end
