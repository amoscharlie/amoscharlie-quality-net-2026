# Persisted pending portfolios are durable delivery intents.
# Enqueue first, then mark dispatched in the same row lock. A crash can duplicate
# a delivery, so PortfolioGeneratorWorker also serializes and skips complete results.
module Portfolios
  class Dispatcher
    STALE_AFTER = 15.minutes
    def initialize(portfolio)
      @portfolio = portfolio
    end
    def call
      return unless @portfolio
      @portfolio.with_lock do
        pending = @portfolio.generation_status == 'pending'
        stale = @portfolio.generation_status == 'generating' && (@portfolio.generation_enqueued_at.nil? || @portfolio.generation_enqueued_at < STALE_AFTER.ago)
        return unless pending || stale
        PortfolioGeneratorWorker.perform_async(@portfolio.session_id)
        @portfolio.update!(generation_status: 'generating', generation_enqueued_at: Time.current)
      end
    end
    def self.recover
      Portfolio.where(generation_status: 'pending').or(
        Portfolio.where(generation_status: 'generating', generation_enqueued_at: Time.current).where('generation_enqueued_at IS NULL OR generation_enqueued_at < ?', STALE_AFTER.ago)
      ).find_each { |portfolio| new(portfolio).call }
    end
  end
end
