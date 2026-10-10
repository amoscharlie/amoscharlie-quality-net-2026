ENV['RAILS_ENV'] = 'test'
ENV['SECRET_KEY_BASE'] ||= 'deterministic-test-secret-not-a-production-credential'
ENV['ALLOWED_ORIGINS'] ||= 'http://localhost:5173'
ENV['GEMINI_API_KEY'] ||= 'offline-test-key'
require File.expand_path('../config/environment', __dir__)
abort('Refusing tests outside test environment') unless Rails.env.test?
require 'rspec/rails'
require 'sidekiq/testing'
Sidekiq::Testing.fake!
RSpec.configure do |config|
  config.use_transactional_fixtures = true
  config.before { Current.clear; Sidekiq::Worker.clear_all }
  config.after { Current.clear }
end
module RiskFixtures
  def organization(scheme)
    Organization.create!(name: scheme, scheme: scheme, identifier: scheme, host: "#{scheme}.localhost")
  end
  def assessment_for(org)
    Current.using(tenant_id: org.id, organization: org) do
      Assessment.create!(name: 'Engineer', time_limit_min: 10, created_by: 1,
        assessment_skills_attributes: [{skill_id: 'SK-ENG-001', skill_label: 'Frontend',
          l1_anchor: 'Guided', l2_anchor: 'Independent', l3_anchor: 'Complex',
          l4_anchor: 'Standards', l5_anchor: 'Strategy', display_order: 0}])
    end
  end
  def session_for(org, status: 'active')
    Current.using(tenant_id: org.id, organization: org) do
      assessment_for(org).sessions.create!(status: status, started_at: status == 'active' ? Time.current : nil)
    end
  end
  def skill_for(portfolio, **extra)
    portfolio.portfolio_skills.create!({skill_id: 'SK-ENG-001', skill_label: 'Frontend', ai_level: 3,
      ai_confidence: 'medium', evidence: ['I measured rendering latency.'], competency_summary: 'Measured trade-offs.'}.merge(extra))
  end
  def auth(org, role: 'admin')
    {'Authorization' => "Bearer #{JsonWebToken.encode(user_id: 1, role: role, scheme: org.scheme)}"}
  end
end
RSpec.configure { |c| c.include RiskFixtures }
