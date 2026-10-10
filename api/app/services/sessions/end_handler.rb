# frozen_string_literal: true

module Sessions
  # Handles session termination: closes the session record, creates the portfolio,
  # and enqueues the portfolio generation job (N10).
  # Called on: manual end, all_covered auto-end, time_ceiling, or error.
  class EndHandler
    VALID_REASONS = Session::END_REASONS

    def initialize(session)
      @session = session
    end

    def call(reason: 'manual_assessor', connection_id: nil)
      reason = 'manual_assessor' unless VALID_REASONS.include?(reason.to_s)
      @session.with_lock do
        return @session if @session.ended?
        return @session if connection_id && @session.audio_connection_id != connection_id
        if reason.to_s == 'all_covered' && !(@session.active? && Coverage::MapInjector.new(@session).all_covered?)
          raise ArgumentError, 'Verified active coverage required'
        end
        duration = @session.started_at ? [(Time.current - @session.started_at).to_i, 0].max : nil
        @session.update!(status: 'ended', end_reason: reason.to_s,
                         ended_at: Time.current, duration_seconds: duration)
        create_portfolio
      end
      enqueue_portfolio_generation
      publish_status_update
      @session
    end

    private

    def publish_status_update
      redis = ::Redis.new(url: ENV.fetch('REDIS_URL', 'redis://localhost:6379/1'))
      redis.publish("coverage:#{@session.id}", { type: 'session_status', status: @session.status, end_reason: @session.end_reason }.to_json)
    rescue => e
      Rails.logger.error("[EndHandler] Failed to publish status update: #{e.message}")
    ensure
      redis&.close
    end

    def create_portfolio
      # Idempotent — only create if one doesn't exist yet
      return if @session.portfolio.present?

      @session.create_portfolio!(
        candidate_id:      @session.candidate_id,
        generation_status: 'pending'
      )
    end

    def enqueue_portfolio_generation
      portfolio = @session.reload.portfolio
      return unless portfolio

      PortfolioGeneratorWorker.perform_async(@session.id)
      Rails.logger.info("[N9/EndHandler] Enqueued N10 for session #{@session.id}")
    end
  end
end
