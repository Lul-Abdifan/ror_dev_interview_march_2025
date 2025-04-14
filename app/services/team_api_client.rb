class TeamApiClient
          include HTTParty
          base_uri ENV['POKEMON_API_BASE_URL']
          
          MAX_CREATURE_ID = 1000 
          
          def self.get_entity(identifier, api_name)
            endpoint = api_name.downcase
            response = get("/#{endpoint}/#{identifier.downcase}")
          
            if response.success?
              result = {
                id: response['id'].to_s,
                name: response['name'],
                url: "#{base_uri}/#{endpoint}/#{response['id']}",
              }
              Rails.logger.info("Successfully fetched data for #{api_name}/#{identifier}")
              result
            else
              Rails.logger.error("TeamApiClient failed for #{api_name}/#{identifier}: #{response.code}")
              nil
            end
          rescue HTTParty::Error => e
            Rails.logger.error("TeamApiClient error for #{api_name}/#{identifier}: #{e.message}")
            nil
          end
          
          
          # Modified method to default to 'pokemon' if no api_name is provided
          def self.get_random_creature(api_name = "pokemon")
            random_id = rand(1..MAX_CREATURE_ID)
            get_entity(random_id.to_s, api_name)
          end
          
          # Debug method to check cache status
        
        end