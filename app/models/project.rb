class Project < ApplicationRecord
  serialize :concerns, coder: JSON
  serialize :analysis_result, coder: JSON

  # Ford: domain concern → candidate architectural characteristics
  CONCERN_CHARACTERISTICS = {
    "time_to_market"        => %w[agility testability deployability],
    "user_satisfaction"     => %w[performance availability fault_tolerance testability deployability agility security],
    "competitive_advantage" => %w[agility testability deployability scalability availability fault_tolerance],
    "time_and_budget"       => %w[simplicity feasibility],
    "mergers_acquisitions"  => %w[interoperability scalability adaptability extensibility]
  }.freeze

  def candidate_characteristics
    (concerns || []).flat_map { |c| CONCERN_CHARACTERISTICS[c] || [] }.uniq
  end
end
