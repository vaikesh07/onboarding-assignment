require 'securerandom'
class KeygenServer
    attr_reader :keys, :available_keys, :deleted_keys
    def initialize
        @KEY_SIZE = 12
        @keys = {}
        @available_keys = Set.new
        @deleted_keys = Set.new
        Thread.new do
            loop do
                sleep 1
                cron
            end
        end
    end
    def generate_keys(count)
        count.times {
            key = random_key
            while @keys[key] || @deleted_keys.include?(key)
                key = random_key
            end
            @keys[key] = {
                'expiry' => Time.now + (5 * 60)
            }
            @available_keys.add key
        }
        @available_keys
    end
    def random_key
        SecureRandom.hex(@KEY_SIZE)
    end
    def get_available_key
        out = nil
        @available_keys.each {|key|
            out = key
            @keys[key]['blocked_till'] = Time.now + 60
            break
        }
        @available_keys.delete out
        out
    end
    def unblock_key(key)
        out = nil
        if @keys[key] && @keys[key]['blocked_till']
            @keys[key] = {
                'expiry' => @keys[key]['expiry']
            }
            @available_keys.add key
            out = key
        end
        out
    end
    def delete_key(key)
        out = nil
        if @keys[key]
            @keys.delete key
            @available_keys.delete key
            @deleted_keys.add key
            out = key
        end
        out
    end
    def keep_alive_key(key)
        out = nil
        if @keys[key]
            @keys[key]['expiry'] = Time.now + (5 * 60)
            out = key
        end
        out
    end
    def cron
        current_time = Time.now
        @keys.each {|key, data|
            unblock_key(key) if data['blocked_till'] && (data['blocked_till'] < current_time)
            delete_key(key) if data['expiry'] < current_time
        }
    end
end