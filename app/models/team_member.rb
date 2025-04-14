class TeamMember < ApplicationRecord
  belongs_to :team

  SLOTS = %w[one two three four five six].freeze

  validates :slot, inclusion: { in: %w[one two three four five six] }
  validates :slot, uniqueness: { scope: :team_id, message: "must be unique within a team" }
  validates :external_id, presence: true
  validates :external_api, presence: true
  validates :external_url, presence: true
end


