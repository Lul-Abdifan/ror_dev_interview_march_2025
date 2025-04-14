class Team < ApplicationRecord
          has_many :team_members, dependent: :destroy
          validates :name, presence: true
          validate :must_have_six_members, on: :update
        
          private
        
          def must_have_six_members
            return unless team_members.any?
            entity_name = team_members.first.external_api
            errors.add(:base, "Team must have exactly six #{entity_name.pluralize}") unless team_members.count == 6
          end
        end


        