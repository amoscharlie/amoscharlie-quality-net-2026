# frozen_string_literal: true

class PortfolioGeneratorWorker
  include Sidekiq::Worker

  sidekiq_options queue: :portfolio, retry: 3

  sidekiq_retries_exhausted do |msg, _ex|
    session_id = msg['args'].first
    session = Session.find_by(id: session_id)
    session&.portfolio&.update(
      generation_status: 'failed',
      generation_error:  "Failed after #{msg['retry_count']} retries: #{msg['error_message']}"
    )
    Rails.logger.error("[N10] Portfolio generation permanently failed for session #{session_id}")
  end

  def perform(session_id)
    session = Session.find(session_id)
    portfolio = session.portfolio || session.create_portfolio!(generation_status: 'pending')
    portfolio.with_lock do
      return if portfolio.complete?
      Portfolios::Generator.new(session: session).call
    end
  rescue ActiveRecord::RecordNotFound
    Rails.logger.warn("[N10] Session #{session_id} not found — skipping")
  rescue StandardError => error
    portfolio&.reload&.update!(generation_status: 'failed', generation_error: error.message)
    raise
  end
end
