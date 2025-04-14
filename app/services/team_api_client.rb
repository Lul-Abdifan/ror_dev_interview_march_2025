class TeamApiClient
          include HTTParty
          base_uri ENV['POKEMON_API_BASE_URL']
          
          MAX_CREATURE_ID = 1000 
          
          def self.get_entity(identifier, api_name)
            cache_key = "entity/#{api_name.downcase}/#{identifier.downcase}"
            
            # Check if the value exists in the cache before fetching
            cached = Rails.cache.exist?(cache_key)
            Rails.logger.info("Cache #{cached ? 'HIT' : 'MISS'} for key: #{cache_key}")
            
            Rails.cache.fetch(cache_key, expires_in: 1.day) do
              Rails.logger.info("Fetching from API for key: #{cache_key}")
              endpoint = api_name.downcase
              response = get("/#{endpoint}/#{identifier.downcase}")
          
              if response.success?
                result = {
                  id: response['id'].to_s,
                  name: response['name'],
                  url: "#{base_uri}/#{endpoint}/#{response['id']}",
                  # moves: response['moves'].map { |move| move['move']['name'] },
                  # abilities: response['abilities'].map { |ability| ability['ability']['name'] }
                }
                Rails.logger.info("Successfully fetched data for #{api_name}/#{identifier}")
                result
              else
                Rails.logger.error("TeamApiClient failed for #{api_name}/#{identifier}: #{response.code}")
                nil
              end
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
          def self.debug_cache(identifier, api_name)
            cache_key = "entity/#{api_name.downcase}/#{identifier.downcase}"
            
            cached = Rails.cache.exist?(cache_key)
            cached_value = Rails.cache.read(cache_key) if cached
            
            puts "Cache key: #{cache_key}"
            puts "Exists in cache: #{cached}"
            if cached
              puts "Cached value: #{cached_value.inspect}"
            else
              puts "Not in cache"
            end
            
            {
              key: cache_key,
              exists: cached,
              value: cached_value
            }
          end
          
          # Method to clear a specific cache entry
          def self.clear_entity_cache(identifier, api_name)
            cache_key = "entity/#{api_name.downcase}/#{identifier.downcase}"
            result = Rails.cache.delete(cache_key)
            puts "Cleared cache for #{cache_key}: #{result ? 'Success' : 'Not found in cache'}"
            result
          end
          
          # Method to test caching performance
          def self.test_caching(identifier, api_name)
            # Clear the cache first
            clear_entity_cache(identifier, api_name)
            
            # First request - should hit the API
            start_time = Time.now
            result1 = get_entity(identifier, api_name)
            api_time = Time.now - start_time
            
            # Second request - should be cached
            start_time = Time.now
            result2 = get_entity(identifier, api_name)
            cache_time = Time.now - start_time
            
            puts "API request took: #{(api_time * 1000).round(2)} ms"
            puts "Cached request took: #{(cache_time * 1000).round(2)} ms"
            puts "Speed improvement: #{(api_time / cache_time).round(2)}x faster"
            puts "Cache working correctly: #{cache_time < api_time}"
            
            {
              api_time_ms: (api_time * 1000).round(2),
              cache_time_ms: (cache_time * 1000).round(2),
              improvement_factor: (api_time / cache_time).round(2),
              cache_working: cache_time < api_time
            }
          end
          
          # Method to check all cache entries related to a specific API
          def self.list_cache_entries(api_name = "pokemon", limit = 10)
            puts "This method only works with Redis or Memcached cache stores"
            puts "For memory store, you'll need to use other debugging methods"
            
            # This is a simplified example and may not work with all cache stores
            if Rails.cache.respond_to?(:redis)
              pattern = "entity/#{api_name.downcase}/*"
              keys = Rails.cache.redis.keys(pattern).first(limit)
              
              puts "Found #{keys.size} cache entries for #{api_name}:"
              keys.each do |key|
                puts "- #{key}"
              end
              
              keys
            else
              puts "Current cache store doesn't support listing keys"
              []
            end
          end
        end