require 'rails_helper'
RSpec.describe 'R01 interview termination outcomes' do
 let!(:session) { session_for(organization('termination')) }
 let(:middleware) { AudioWebSocketMiddleware.new(->(_) {}) }
 let(:browser) { double(send:nil,close:nil) }
 let(:state) { AudioWebSocketMiddleware::ConnectionState.new }
 let(:events) { [] }
 let(:timers) { [] }
 before do
  state.session=session; state.connection_id=session.audio_connection_id
  allow(Thread).to receive(:new) { |&b| b.call }
  allow(EM).to receive(:schedule) { |&b| b.call }
  allow(EM).to receive(:add_timer) { |delay,&b| timers << [delay,b] }
  allow(middleware).to receive(:send_json) { |_,**payload| events << payload }
 end
 def covered!
  session.coverage_maps.create!(skill_id:'SK-ENG-001',skill_label:'Frontend',state:'covered',probe_count:3,is_discovered:false)
 end
 it 'fails truthfully when AI closes with unverified coverage instead of entering draining' do
  middleware.send(:finalize_natural_close,browser,state,session)
  expect(session.reload.end_reason).to eq('error')
  expect(events).to include(hash_including(type:'session_ended',reason:'error'))
  expect(events).not_to include(hash_including(type:'preparing_to_end'))
  expect(session.portfolio).to be_present
 end
 it 'waits for audio acknowledgment when coverage is verified' do
  covered!
  middleware.send(:finalize_natural_close,browser,state,session)
  expect(session.reload.status).to eq('active')
  expect(events).to include(hash_including(type:'preparing_to_end',reason:'all_covered'))
  expect(events).not_to include(hash_including(type:'session_ended'))
 end
 it 'ends with error rather than crashing on timeout with unverified coverage' do
  middleware.send(:poll_for_session_end,browser,state,session,attempts:30)
  timers.find { |delay,_| delay==1 }.last.call
  expect(session.reload.end_reason).to eq('error')
  expect(events).to include(hash_including(type:'session_ended',reason:'error'))
 end
 it 'preserves the persisted error reason when a delayed poll sees an ended session' do
  Sessions::EndHandler.new(session).call(reason:'error')
  middleware.send(:poll_for_session_end,browser,state,session,attempts:0)
  timers.find { |delay,_| delay==1 }.last.call
  expect(events).to include(hash_including(type:'session_ended',reason:'error'))
  expect(events).not_to include(hash_including(type:'session_ended',reason:'all_covered'))
 end
 it 'ends verified coverage once on server timeout if acknowledgment is missing' do
  covered!
  middleware.send(:poll_for_session_end,browser,state,session,attempts:30)
  timers.find { |delay,_| delay==1 }.last.call
  expect(session.reload.end_reason).to eq('all_covered')
  expect(PortfolioGeneratorWorker.jobs.size).to eq(1)
  expect(events).to include(hash_including(type:'session_ended',reason:'all_covered'))
 end
end
