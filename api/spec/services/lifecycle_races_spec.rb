require 'rails_helper'
RSpec.describe 'Lifecycle competing callers' do
 let!(:session) { session_for(organization('races')) }
 it 'A10 a stale session object cannot queue termination twice' do
  stale=Session.find(session.id)
  Sessions::EndHandler.new(session).call(reason:'manual_candidate')
  Sessions::EndHandler.new(stale).call(reason:'manual_candidate')
  expect(Portfolio.where(session_id:session.id).count).to eq(1)
  expect(PortfolioGeneratorWorker.jobs.size).to eq(1)
 end
 it 'A10 preserves distinct turns arriving with the same connection-local counter' do
  middleware=AudioWebSocketMiddleware.new(->(_) {})
  middleware.send(:save_transcript_turn,session,1,'candidate','First answer')
  middleware.send(:save_transcript_turn,session,1,'ai','Follow up question')
  expect(session.transcript_turns.ordered.pluck(:text)).to eq(['First answer','Follow up question'])
  expect(session.transcript_turns.ordered.pluck(:turn_number)).to eq([1,2])
 end
 it 'A10 old disconnect timer cannot end a reconnected interview' do
  middleware=AudioWebSocketMiddleware.new(->(_) {})
  state=AudioWebSocketMiddleware::ConnectionState.new;state.session=session
  old_disconnect=Time.current-30;state.browser_disconnected_at=old_disconnect
  timer_callback=nil
  allow(EM::Timer).to receive(:new) { |_,&block| timer_callback=block; double(cancel:nil) }
  allow(Thread).to receive(:new) { |&block| block.call }
  allow(EM).to receive(:schedule) { |&block| block.call }
  middleware.send(:schedule_graceful_end,double,state)
  allow(middleware).to receive(:authenticate_and_load).and_return([Session.find(session.id),nil])
  allow(middleware).to receive(:connect_to_gemini)
  middleware.send(:handle_browser_open,{},session.id,double,AudioWebSocketMiddleware::ConnectionState.new)
  timer_callback.call
  expect(session.reload.status).to eq('active')
  expect(PortfolioGeneratorWorker.jobs).to be_empty
 end
end
