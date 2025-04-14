class TeamsController < ApplicationController
          skip_before_action :verify_authenticity_token, only: [:create, :update, :destroy_member]
          before_action :set_team, only: [:show, :update, :destroy_member]
          
          # GET /teams
          def index
            @teams = Team.all.includes(:team_members)
            render json: @teams.as_json(include: :team_members), status: :ok
          end
        
          # GET /teams/:id
          def show
            if @team
              render json: @team.as_json(include: :team_members), status: :ok
            else
              render json: { error: "Team not found" }, status: :not_found
            end
          end
        
          def create
            @team = Team.new(team_params)
            if build_team_members
              if @team.save
                render json: @team.as_json(include: :team_members), status: :created
              else
                render json: @team.errors, status: :unprocessable_entity
              end
            else
              render json: { error: "Invalid or insufficient creatures provided; exactly six required" }, status: :unprocessable_entity
            end
          end
        
          # PATCH /teams/:id/update_slot/:slot
          def update
            slot = params[:slot]
            unless TeamMember::SLOTS.include?(slot)
              Rails.logger.debug "Invalid slot: #{slot}"
              return render json: { error: "Invalid slot" }, status: :bad_request
            end
            
            team_member = @team.team_members.find_by(slot: slot)
            if team_member.nil?
              Rails.logger.debug "Team member not found in slot #{slot}"
              return render json: { error: "Team member not found in this slot" }, status: :not_found
            end
            
            identifier = params[:external_id]
            api_name = params[:api_name] || 'pokemon'
            
            entity = TeamApiClient.get_entity(identifier, api_name)
            if entity.nil?
              Rails.logger.debug "Creature not found for external_id #{identifier} and api_name #{api_name}"
              return render json: { error: "Creature not found in external API" }, status: :unprocessable_entity
            end
            
            if team_member.update(external_id: entity[:id], external_api: api_name, external_url: entity[:url])
              render json: team_member, status: :ok
            else
              render json: team_member.errors, status: :unprocessable_entity
            end
          end
          
          # DELETE /teams/:id/slot/:slot
          def destroy_member
            slot = params[:slot]
            unless TeamMember::SLOTS.include?(slot)
              return render json: { error: "Invalid slot" }, status: :bad_request
            end
            
            team_member = @team.team_members.find_by(slot: slot)
            if team_member.nil?
              return render json: { error: "Team member not found in this slot" }, status: :not_found
            end
            
            if team_member.destroy
              render json: { message: "Team member removed successfully" }, status: :ok
            else
              render json: { error: "Failed to remove team member" }, status: :unprocessable_entity
            end
          end
        
          private
          
          def set_team
            @team = Team.find_by(id: params[:id])
            if @team.nil?
              Rails.logger.debug "Team not found with id #{params[:id]}"
              render json: { error: "Team not found" }, status: :not_found
            end
          end
        
          def team_params
            params.require(:team).permit(:name)
          end
        
          def build_team_members
            entity_identifiers = params[:team][:entity_identifiers]&.reject(&:blank?) || []
            api_name = params[:team][:api_name] || 'pokemon'
        
            if entity_identifiers.size < 6
              (6 - entity_identifiers.size).times do
                entity = TeamApiClient.get_random_creature(api_name)
                return false unless entity
                entity_identifiers << entity[:id]
              end
            end
        
            return false if entity_identifiers.size != 6
        
            slots = %w[one two three four five six]
            entity_identifiers.each_with_index do |identifier, index|
              entity = TeamApiClient.get_entity(identifier, api_name)
              return false unless entity
              @team.team_members.build(
                slot: slots[index],
                external_id: entity[:id],
                external_api: api_name,
                external_url: entity[:url]
              )
            end
            true
          end
        end