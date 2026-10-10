require 'rails_helper'
RSpec.describe 'Persisted evidence boundaries' do
  let!(:org) { organization('evidence') }
  let!(:session) { session_for(org) }
  let(:valid_skill) { {'skill_id'=>'SK-ENG-001','skill_label'=>'Frontend','level'=>3,'confidence'=>'medium',
    'evidence'=>['I measured rendering latency.'],'competency_summary'=>'Measured trade-offs.'} }
  before do
    session.transcript_turns.create!(turn_number: 1, speaker: 'candidate', text: 'I measured rendering latency.')
    session.coverage_maps.create!(skill_id:'SK-ENG-001',skill_label:'Frontend',state:'partial',probe_count:2)
  end
  def generate(payload)
    client = instance_double(Gemini::HttpClient, generate_content: payload)
    Portfolios::Generator.new(session: session, gemini_client: client).call
  end
  it 'A05 rejects an empty AI response instead of publishing an empty complete portfolio' do
    expect { generate({}) }.to raise_error(StandardError)
    expect(session.reload.portfolio.generation_status).to eq('failed')
  end
  it 'A05 rejects out-of-range levels instead of silently clamping' do
    expect { generate({'configured_skills'=>[valid_skill.merge('level'=>9)],'discovered_skills'=>[]}) }.to raise_error(StandardError)
    expect(session.reload.portfolio.generation_status).to eq('failed')
  end
  it 'A05 rejects invented evidence quotes' do
    expect { generate({'configured_skills'=>[valid_skill.merge('evidence'=>['I led a team of fifty.'])],'discovered_skills'=>[]}) }.to raise_error(StandardError)
  end
  it 'A05 preserves prior skills if a replacement response is invalid' do
    portfolio = session.create_portfolio!(generation_status:'failed')
    previous = skill_for(portfolio)
    expect { generate({'configured_skills'=>[valid_skill,valid_skill.merge('skill_label'=>'','skill_id'=>'extra')],'discovered_skills'=>[]}) }.to raise_error(StandardError)
    expect(portfolio.reload.portfolio_skills.pluck(:id)).to eq([previous.id])
  end
  it 'publishes a valid grounded rating without changing its level or evidence' do
    p = generate({'configured_skills'=>[valid_skill],'discovered_skills'=>[]})
    expect(p.generation_status).to eq('complete')
    expect(p.portfolio_skills.first.ai_level).to eq(3)
    expect(p.portfolio_skills.first.evidence).to eq(valid_skill['evidence'])
  end
  it 'A06 does not turn absent analysis into evidence of coverage' do
    map = session.coverage_maps.first; map.update!(probe_count:4)
    analyzer = instance_double(Coverage::Analyzer, call: {skill_updates:[],discovered_skills:[]})
    allow(Coverage::Analyzer).to receive(:new).and_return(analyzer)
    CoverageAnalyzerWorker.new.perform(session.id, 1)
    expect(map.reload.state).to eq('partial')
    expect(map.last_signal).to be_nil
  end
end
