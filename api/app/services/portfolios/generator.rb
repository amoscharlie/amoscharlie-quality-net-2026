# frozen_string_literal: true

module Portfolios
  # N10: Generates a structured skill portfolio from the full transcript
  # and final coverage map using Gemini Pro.
  # Runs post-session as a background job.
  class Generator
    def initialize(session:, gemini_client: nil)
      @session = session
      @gemini_client = gemini_client || Gemini::HttpClient.new(
        model:   ENV.fetch('GEMINI_PRO_MODEL', 'gemini-2.0-pro-001'),
        timeout: 180  # up to 3 minutes for large transcripts
      )
    end

    # Returns the Portfolio record with skills populated.
    def call
      portfolio = @session.portfolio || @session.create_portfolio!(
        candidate_id:      @session.candidate_id,
        generation_status: 'pending'
      )

      portfolio.update!(generation_status: 'generating')

      prompt   = build_prompt
      response = @gemini_client.generate_content(prompt, temperature: 0.2)

      Portfolio.transaction do
        save_skills(portfolio, response)
        portfolio.update!(generation_status: 'complete', generation_error: nil, generated_at: Time.current)
      end

      Rails.logger.info("[N10] Portfolio generated for session #{@session.id}")
      portfolio
    rescue => e
      portfolio&.update!(generation_status: 'failed', generation_error: e.message)
      Rails.logger.error("[N10] Portfolio generation failed for session #{@session.id}: #{e.class} #{e.message}")
      raise
    end

    private

    def build_prompt
      assessment       = @session.assessment
      configured_skills = assessment.assessment_skills.order(:display_order)
      coverage_maps     = @session.coverage_maps.order(:id)
      turns             = @session.transcript_turns.ordered

      skills_text = configured_skills.map { |s| skill_definition_block(s) }.join("\n\n")

      coverage_json = {
        skills:     coverage_maps.reject(&:is_discovered).map { |m| coverage_json(m) },
        discovered: coverage_maps.select(&:is_discovered).map { |m| coverage_json(m) }
      }.to_json

      transcript_text = turns.map { |t| "[#{t.speaker.upcase}]: #{t.text}" }.join("\n")

      <<~PROMPT
        You are evaluating a completed skills assessment interview to produce a structured skill portfolio.

        ROLE BEING ASSESSED: #{assessment.name}

        SKILL DEFINITIONS AND BEHAVIORAL ANCHORS:
        #{skills_text}

        UNIVERSAL L1-L5 ANCHORS (use for discovered skills):
        L1 — Executes with explicit guidance and close review. Understands conceptually but cannot apply independently.
        L2 — Executes independently on routine scope. Uses known patterns. Handles common cases but not edge cases.
        L3 — Executes complex, ambiguous scope. Makes tradeoffs. Handles edge cases. Can teach L1-L2.
        L4 — Defines standards and creates reusable systems. Resolves systemic problems. Cross-team impact.
        L5 — Org-level authority. Shapes how the skill is practiced. Rare.

        FINAL COVERAGE MAP:
        #{coverage_json}

        FULL INTERVIEW TRANSCRIPT:
        #{transcript_text}

        ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        TASK
        ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

        For EACH skill in the coverage map (both configured and discovered):

        1. FIND THE EVIDENCE
           Read all transcript turns where this skill was discussed.
           Identify the 2-3 most revealing quotes from the CANDIDATE (not the AI).
           A quote is revealing if it shows HOW they think, not just WHAT they know.

        2. ASSIGN A LEVEL
           Compare the candidate's actual behavior to the L1-L5 anchors.
           Assign the highest level where you see CONSISTENT evidence, not just one strong moment.
           If evidence is mixed (mostly L2 with one L3 moment), assign L2.

        3. WRITE THE COMPETENCY SUMMARY
           2-3 sentences. Focus on patterns, not individual answers.
           What does this person reliably do at this skill? What's the ceiling? What's missing?

        4. ASSIGN CONFIDENCE
           high — probe_count >= 3 AND state = covered
           medium — probe_count = 2 OR state = partial
           low — probe_count <= 1 OR state = initiated

        OUTPUT (JSON only, no prose):
        {
          "configured_skills": [
            {
              "skill_id": "sk-eng-001",
              "skill_label": "React / Frontend Development",
              "level": 3,
              "confidence": "high",
              "evidence": ["quote 1", "quote 2", "quote 3"],
              "competency_summary": "2-3 sentence summary"
            }
          ],
          "discovered_skills": [
            {
              "skill_label": "Micro-frontend Architecture",
              "level": 2,
              "confidence": "low",
              "evidence": ["quote 1"],
              "competency_summary": "2-3 sentence summary"
            }
          ]
        }
      PROMPT
    end

    def skill_definition_block(skill)
      lines = ["━━━━━━━━━━━━━━━"]
      lines << "SKILL: #{skill.skill_label} (#{skill.skill_id || 'custom'})"
      lines << "SCOPE: #{skill.scope_include}" if skill.scope_include.present?
      lines << ""
      lines << "L1 — #{skill.l1_anchor}"
      lines << "L2 — #{skill.l2_anchor}"
      lines << "L3 — #{skill.l3_anchor}"
      lines << "L4 — #{skill.l4_anchor}"
      lines << "L5 — #{skill.l5_anchor}"
      lines.join("\n")
    end

    def coverage_json(map)
      {
        id:          map.skill_id || map.skill_label.downcase.gsub(/\s+/, '-'),
        label:       map.skill_label,
        state:       map.state,
        probe_count: map.probe_count,
        is_discovered: map.is_discovered
      }
    end

    def save_skills(portfolio, response)
      data = response.is_a?(Hash) ? response : JSON.parse(response)

      validate_response!(data)
      portfolio.with_lock do
        portfolio.portfolio_skills.destroy_all
        [['configured_skills', false], ['discovered_skills', true]].each do |key, discovered|
          data.fetch(key).each do |row|
            portfolio.portfolio_skills.create!(
              skill_id: discovered ? nil : row['skill_id'], skill_label: row['skill_label'],
              is_discovered: discovered, ai_level: row['level'], ai_confidence: row['confidence'],
              evidence: row['evidence'], competency_summary: row['competency_summary'])
          end
        end
      end
    end

    def validate_response!(data)
      raise ArgumentError, 'Expected both skill arrays' unless data.is_a?(Hash) &&
        %w[configured_skills discovered_skills].all? { |k| data[k].is_a?(Array) }
      configured = @session.assessment.assessment_skills.to_a
      actual = data['configured_skills']
      identity = ->(skill) { [skill.skill_id, skill.skill_label] }
      supplied = actual.map { |row| row.is_a?(Hash) ? [row['skill_id'], row['skill_label']] : nil }
      raise ArgumentError, 'Configured skills do not match assessment' unless
        supplied.sort_by(&:to_s) == configured.map(&identity).sort_by(&:to_s)
      candidate_turns = @session.transcript_turns.where(speaker: 'candidate').pluck(:text)
      normalize = ->(text) { text.gsub(/\s+/, ' ').strip }
      candidate_text = candidate_turns.map(&normalize)
      rows = actual + data['discovered_skills']
      labels = rows.map { |row| row.is_a?(Hash) ? row['skill_label'] : nil }
      raise ArgumentError, 'Duplicate or missing skill labels' unless labels.all?(&:present?) && labels.uniq.size == labels.size
      discovered_labels = @session.coverage_maps.where(is_discovered: true).pluck(:skill_label)
      raise ArgumentError, 'Unknown discovered skill' unless data['discovered_skills'].all? { |row| discovered_labels.include?(row['skill_label']) }
      rows.each do |row|
        raise ArgumentError, 'Invalid rating' unless row['level'].is_a?(Integer) && (1..5).cover?(row['level'])
        raise ArgumentError, 'Invalid confidence' unless PortfolioSkill::CONFIDENCE_LEVELS.include?(row['confidence'])
        raise ArgumentError, 'Missing competency summary' unless row['competency_summary'].is_a?(String) && row['competency_summary'].present?
        quotes = row['evidence']
        raise ArgumentError, 'Evidence must contain 1-3 candidate quotes' unless quotes.is_a?(Array) && (1..3).cover?(quotes.size)
        unless quotes.all? { |q| q.is_a?(String) && normalize.call(q).present? && candidate_text.any? { |t| t.include?(normalize.call(q)) } }
          raise ArgumentError, 'Evidence quote not found in candidate transcript'
        end
        map = @session.coverage_maps.find_by(skill_label: row['skill_label'])
        if row['confidence'] == 'high' && !(map && map.state == 'covered' && map.probe_count >= 3)
          raise ArgumentError, 'High confidence is unsupported by coverage'
        end
      end
    end
  end
end
