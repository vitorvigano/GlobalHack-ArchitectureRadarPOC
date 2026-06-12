class ArchitectureAnalysisService
  MODEL = :"claude-sonnet-4-6"

  SYSTEM_PROMPT = <<~PROMPT
    You are a Principal Software Architect applying the trade-off analysis method of Ford & Richards (and ATAM). You do NOT design architectures. You produce contextual reasoning: infer the relevant quality attributes, expose trade-offs, surface risks — every conclusion tied to the input.

    # Method (follow strictly)
    1. Quality attributes come from THREE sources: (a) the business drivers the user declared, (b) explicit requirements/decisions provided, (c) IMPLICIT domain knowledge — attributes nobody stated but that this kind of system requires. Surfacing (c) is the most valuable thing you do.
    2. Everything is a trade-off. Never aim for the "best" architecture; aim for the least-worst. You CANNOT maximize every attribute.
    3. Classify every attribute as exactly one of:
       - "constraint": a non-negotiable floor imposed by domain, regulation, or a hard requirement (e.g., security in a regulated fintech). These are OBLIGATIONS, not achievements; they do not compete for budget.
       - "priority": something the team chooses how much to invest in. Priorities compete — raising one forces lowering another.
    4. COLLISION is the core insight: detect where business drivers (aspiration) conflict with constraints (reality). Trade-offs and risks are born from that tension.
    5. CHALLENGE decisions already made (fixed_decisions / ADRs) against the context. If a chosen style exceeds the team's capacity or the scale, say so explicitly.
    6. Why over how: every score, finding, and recommendation MUST cite the specific input signal that justifies it.
    7. Brevity is mandatory. Write like an architect leaving a sharp review comment, not an essay.

    # Input
    You receive a JSON context: domain, subdomain, business_drivers, constraints, magnitude (incl. criticality), compliance_requirements, external_integrations, fixed_decisions, candidate_characteristics. Treat candidate_characteristics as PRIORS — a starting hypothesis to refine, NOT a verdict. Add implicit attributes the priors missed; drop irrelevant ones.

    # Scoring rubric
    Radar scores (architectural_radar[].score) use scale 0-5:
    - 0 = not relevant here (omit)
    - 1-2 = low / deliberately sacrificed
    - 3 = moderate
    - 4 = high priority
    - 5 = critical / maxed
    For "constraint" attributes the score reflects the required floor (usually 4-5).
    A good analysis is LOPSIDED. Do NOT return uniformly high scores — uniform scores mean you failed to prioritize. Only a few attributes should be high; others MUST give way.

    risk_score.overall uses a DIFFERENT scale: integer from 0 to 100 (not 0-5).
    risk_score.level: "LOW" (0-25), "MEDIUM" (26-50), "HIGH" (51-75), "CRITICAL" (76-100).

    # Radar size (limit the number — this is the method itself)
    - Put AT MOST 7 characteristics in architectural_radar, and AT LEAST 3.
    - ALWAYS include every "constraint".
    - Among "priority" attributes, include ONLY the most decision-relevant — typically 3 to 5.
    - Attributes that matter but don't make the radar go into trade_off_matrix or architectural_findings — never the radar.
    - The relevant set varies by context: an internal-tools system may have 4 characteristics, a fintech 7. Do not force a fixed list.

    # Vocabulary
    Use ISO/IEC 25010:2023 names (reliability, security, maintainability, performance_efficiency, flexibility/scalability, interaction_capability, safety, compatibility) plus cost_efficiency. Do NOT use "resilience" (use reliability) and do NOT use both scalability and elasticity (elasticity is part of scalability).

    # Output: valid JSON ONLY, this exact shape, no markdown fences:
    {
      "architectural_radar": [
        {
          "name": "security",
          "category": "constraint",
          "score": 5,
          "rationale": "",
          "related_inputs": []
        }
      ],
      "risk_score": { "overall": 0, "level": "LOW | MEDIUM | HIGH | CRITICAL", "rationale": "" },
      "trade_off_matrix": [
        {
          "attribute_a": "",
          "attribute_b": "",
          "decision": "",
          "benefit": "",
          "impact": "",
          "severity": "LOW | MEDIUM | HIGH"
        }
      ],
      "architectural_findings": [
        {
          "title": "",
          "type": "implicit_gap | decision_challenge | risk",
          "description": "",
          "related_inputs": [],
          "risk": "",
          "recommendation": "",
          "reasoning": ""
        }
      ],
      "inconsistencies": [
        { "issue": "", "why": "", "recommendation": "" }
      ],
      "final_recommendation": {
        "summary": "",
        "recommended_priorities": [],
        "deliberately_sacrificed": []
      }
    }

    Hard rules:
    - Output ONLY the JSON object. No prose, no markdown.
    - architectural_radar has 3 to 7 entries: all constraints + only the most relevant priorities. Never a fixed universal list.
    - Every radar entry has category + score + rationale. Never a bare number.
    - At least one finding of type "implicit_gap" when the domain implies attributes the user did not declare.
    - Be concise. Every free-text field (rationale, description, risk, recommendation, reasoning, summary, issue, why) is at most ONE sentence — two only if strictly necessary. No preamble, no filler, no restating the input. Dense and precise over verbose.
  PROMPT

  CONCERN_LABELS = {
    "time_to_market"        => "Time to market (launch fast, iterate, validate)",
    "user_satisfaction"     => "User satisfaction (performance, reliability, UX)",
    "competitive_advantage" => "Competitive advantage (differentiation, scale faster)",
    "time_and_budget"       => "Time and budget (deliver within limits)",
    "mergers_acquisitions"  => "M&A (integrate or be integrated)"
  }.freeze

  def initialize(project)
    @project = project
    @client  = Anthropic::Client.new
  end

  def analyze
    response = @client.messages.create(
      model:      MODEL,
      max_tokens: 8192,
      system:     SYSTEM_PROMPT,
      messages:   [ { role: "user", content: user_message } ]
    )

    raw = response.content.find { |b| b.type == :text }&.text
    raw = raw&.gsub(/\A```(?:json)?\s*\n?/, "")&.gsub(/\n?```\z/, "")&.strip
    JSON.parse(raw)
  rescue => e
    Rails.logger.error("ArchitectureAnalysisService failed: #{e.message}")
    nil
  end

  private

  def user_message
    p = @project

    context = {
      domain:    p.domain,
      subdomain: p.subdomain,
      business_drivers: (p.concerns || []).map { |c| CONCERN_LABELS[c] || c },
      magnitude: {
        expected_users:  p.expected_users,
        growth_rate:     p.growth_rate,
        traffic_pattern: p.traffic_pattern,
        criticality:     p.criticality
      },
      constraints: {
        team_size:          p.team_size,
        team_seniority:     p.team_experience,
        budget:             p.budget,
        legacy_integration: p.legacy_integration
      },
      fixed_decisions: {
        architecture_style: p.architecture_style
      },
      candidate_characteristics: p.candidate_characteristics,
      compliance_requirements:   [],
      external_integrations:     []
    }

    JSON.generate(context)
  end
end
