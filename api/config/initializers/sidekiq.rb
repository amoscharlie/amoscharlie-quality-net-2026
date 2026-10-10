# frozen_string_literal: true

SIDEKIQ_STATUS_FILE = Rails.root.join('tmp/sidekiq_status').freeze

Sidekiq.configure_server do |config|
  config.redis = { url: ENV.fetch('REDIS_URL', 'redis://localhost:6379/1') }

  config.on(:startup) do
    FileUtils.mkdir_p(Rails.root.join('tmp'))
    File.write(SIDEKIQ_STATUS_FILE, "READY: 1\n")
    # Independent database polling survives Redis downtime while Sidekiq stays up.
    config.instance_variable_set(:@portfolio_delivery_thread, Thread.new do
      loop do
        begin
          ActiveRecord::Base.connection_pool.with_connection { Portfolios::Dispatcher.recover }
        rescue StandardError => error
          Rails.logger.error("[DeliveryRecovery] #{error.class}: #{error.message}")
        end
        sleep 30
      end
    end)
  end

  config.on(:shutdown) do
    config.instance_variable_get(:@portfolio_delivery_thread)&.kill
    File.delete(SIDEKIQ_STATUS_FILE)
  rescue StandardError
    nil
  end
end

Sidekiq.configure_client do |config|
  config.redis = { url: ENV.fetch('REDIS_URL', 'redis://localhost:6379/1') }
end
