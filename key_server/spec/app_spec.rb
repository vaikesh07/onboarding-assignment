# spec/app_spec.rb
#
# RSpec tests for the Sinatra application (app.rb) endpoints.
# Uses Rack::Test to simulate HTTP requests.

require 'rspec'
require 'rack/test'
require 'json'
require 'timecop' # For time manipulation
require_relative '../app' # Load the Sinatra app and KeyManager

# Configure Rack::Test for Sinatra app
RSpec.configure do |config|
  config.include Rack::Test::Methods

  # Override the default `app` method for Rack::Test to ensure a controlled KeyManager
  def app
    # Initialize the global KeyManager *without* starting its cleanup thread for testing.
    # The cleanup thread will be started/stopped explicitly by RSpec hooks.
    $key_manager = KeyManager.new(start_thread_on_init: false) unless defined?($key_manager) && $key_manager.is_a?(KeyManager)
    Sinatra::Application
  end

  # This `before(:suite)` hook runs once before all tests in the suite.
  # It's responsible for starting the background cleanup thread for the entire test run.
  config.before(:suite) do
    # Ensure a single KeyManager instance for the suite, and start its thread.
    $key_manager = KeyManager.new(start_thread_on_init: false)
    $key_manager.start_cleanup_thread
    puts "\n[RSpec Setup] KeyManager cleanup thread started for the test suite."
  end

  # This `after(:suite)` hook runs once after all tests in the suite.
  # It's responsible for stopping the background cleanup thread.
  config.after(:suite) do
    if defined?($key_manager) && $key_manager.is_a?(KeyManager)
      $key_manager.stop_cleanup_thread
      puts "\n[RSpec Teardown] KeyManager cleanup thread stopped after test suite."
    end
    # Restore the default cleanup interval if it was modified for tests.
    KeyManager.send(:remove_const, :CLEANUP_INTERVAL_SECONDS)
    KeyManager.const_set(:CLEANUP_INTERVAL_SECONDS, 10)
  end

  # This `before(:each)` hook runs before each individual test example.
  # It resets the state of the KeyManager, preparing it for a new test scenario,
  # but crucially, it does *not* stop or restart the background thread.
  config.before(:each) do
    $key_manager.reset_state
    Timecop.return # Ensure time is unfrozen before each test starts, just in case.
  end
end

RSpec.describe 'API Key Management Endpoints' do
  describe 'POST /generate (E1)' do
    it 'generates a new API key' do
      post '/generate'
      expect(last_response).to be_ok
      expect(last_response.content_type).to eq('application/json')
      json_response = JSON.parse(last_response.body)
      expect(json_response).to have_key('key_id')
      expect(json_response['key_id']).to be_a(String)
      expect(json_response['key_id'].length).to be > 0
    end

    it 'adds the generated key to the manager' do
      expect { post '/generate' }.to change { $key_manager.total_keys_count }.by(1)
      expect($key_manager.available_keys_count).to eq(1)
    end
  end

  describe 'GET /key (E2)' do
    context 'when available keys exist' do
      before { $key_manager.generate_key } # Create one available key

      it 'returns an available key' do
        get '/key'
        expect(last_response).to be_ok
        json_response = JSON.parse(last_response.body)
        expect(json_response).to have_key('key_id')
        expect(json_response['key_id']).to be_a(String)
      end

      it 'blocks the retrieved key' do
        key_id = JSON.parse(post('/generate').body)['key_id'] # Get key from generate
        get '/key' # This will get a key
        expect($key_manager.key_status(JSON.parse(last_response.body)['key_id'])).to eq(:blocked)
      end

      it 'removes the key from the available pool' do
        expect($key_manager.available_keys_count).to eq(1)
        get '/key'
        expect($key_manager.available_keys_count).to eq(0)
      end
    end

    context 'when no available keys exist' do
      it 'returns a 404 status' do
        get '/key'
        expect(last_response.status).to eq(404)
        json_response = JSON.parse(last_response.body)
        expect(json_response['error']).to eq('No available keys.')
      end
    end
  end

  describe 'POST /unblock/:key_id (E3)' do
    let!(:key_id) { JSON.parse(post('/generate').body)['key_id'] }
    before { get '/key' } # Block the key

    context 'when key is blocked' do
      it 'unblocks the key successfully' do
        post "/unblock/#{key_id}"
        expect(last_response).to be_ok
        json_response = JSON.parse(last_response.body)
        expect(json_response['message']).to eq("Key '#{key_id}' unblocked successfully.")
        expect($key_manager.key_status(key_id)).to eq(:available)
        expect($key_manager.available_keys_count).to eq(1)
      end

      it 'resets the expiry of the key' do
        original_key_obj = $key_manager.instance_variable_get(:@keys)[key_id]
        original_expiry = original_key_obj.expires_at

        # Simulate time passing before unblocking
        Timecop.travel(Time.now + 100) do
          post "/unblock/#{key_id}"
          updated_key_obj = $key_manager.instance_variable_get(:@keys)[key_id]
          new_expiry = updated_key_obj.expires_at
          # New expiry should be 5 mins from the *new* Time.now
          expect(new_expiry).to be_within(1).of(Time.now + KeyManager::KEY_INITIAL_EXPIRY_SECONDS)
          expect(new_expiry).not_to eq(original_expiry)
        end
      end
    end

    context 'when key is not blocked' do
      it 'returns 404 if key is available' do
        post "/unblock/#{key_id}" # Unblock it first
        post "/unblock/#{key_id}" # Try to unblock again when it's available
        expect(last_response.status).to eq(404)
        json_response = JSON.parse(last_response.body)
        expect(json_response['error']).to include('not in a blockable state')
      end

      it 'returns 404 if key is deleted' do
        delete "/delete/#{key_id}" # Delete it
        post "/unblock/#{key_id}"
        expect(last_response.status).to eq(404)
        json_response = JSON.parse(last_response.body)
        expect(json_response['error']).to include('not found or not in a blockable state')
      end
    end

    context 'when key does not exist' do
      it 'returns 404' do
        post '/unblock/non_existent_key'
        expect(last_response.status).to eq(404)
        json_response = JSON.parse(last_response.body)
        expect(json_response['error']).to include('not found or not in a blockable state')
      end
    end
  end

  describe 'DELETE /delete/:key_id (E4)' do
    let!(:key_id) { JSON.parse(post('/generate').body)['key_id'] }

    it 'deletes an available key successfully' do
      expect($key_manager.total_keys_count).to eq(1)
      delete "/delete/#{key_id}"
      expect(last_response.status).to eq(204) # No Content
      expect($key_manager.total_keys_count).to eq(0)
    end

    it 'deletes a blocked key successfully' do
      get '/key' # Block the key
      expect($key_manager.total_keys_count).to eq(1)
      delete "/delete/#{key_id}"
      expect(last_response.status).to eq(204)
      expect($key_manager.total_keys_count).to eq(0)
    end

    it 'returns 404 if key does not exist' do
      delete '/delete/non_existent_key'
      expect(last_response.status).to eq(404)
      json_response = JSON.parse(last_response.body)
      expect(json_response['error']).to eq('Key \'non_existent_key\' not found.')
    end
  end

  describe 'POST /keep_alive/:key_id (E5)' do
    let!(:key_id) { JSON.parse(post('/generate').body)['key_id'] }

    it 'successfully keeps an available key alive' do
      original_key_obj = $key_manager.instance_variable_get(:@keys)[key_id]
      original_expiry = original_key_obj.expires_at

      # Simulate time passing to verify expiry reset
      Timecop.travel(Time.now + 100) do
        post "/keep_alive/#{key_id}"
        expect(last_response).to be_ok
        json_response = JSON.parse(last_response.body)
        expect(json_response['message']).to eq("Key '#{key_id}' keep-alive successful.")

        updated_key_obj = $key_manager.instance_variable_get(:@keys)[key_id]
        new_expiry = updated_key_obj.expires_at
        expect(new_expiry).to be_within(1).of(Time.now + KeyManager::KEY_INITIAL_EXPIRY_SECONDS)
        expect(new_expiry).not_to eq(original_expiry)
      end
    end

    it 'successfully keeps a blocked key alive' do
      get '/key' # Block the key
      original_key_obj = $key_manager.instance_variable_get(:@keys)[key_id]
      original_expiry = original_key_obj.expires_at

      Timecop.travel(Time.now + 100) do
        post "/keep_alive/#{key_id}"
        expect(last_response).to be_ok
        updated_key_obj = $key_manager.instance_variable_get(:@keys)[key_id]
        new_expiry = updated_key_obj.expires_at
        expect(new_expiry).to be_within(1).of(Time.now + KeyManager::KEY_INITIAL_EXPIRY_SECONDS)
        expect(new_expiry).not_to eq(original_expiry)
      end
    end

    it 'returns 404 if key does not exist' do
      post '/keep_alive/non_existent_key'
      expect(last_response.status).to eq(404)
      json_response = JSON.parse(last_response.body)
      expect(json_response['error']).to eq('Key \'non_existent_key\' not found or not active.')
    end

    it 'returns 404 if key is deleted' do
      delete "/delete/#{key_id}"
      post "/keep_alive/#{key_id}"
      expect(last_response.status).to eq(404)
      json_response = JSON.parse(last_response.body)
      expect(json_response['error']).to eq('Key \'' + key_id + '\' not found or not active.')
    end
  end

  describe 'Automatic Key Expiration and Auto-Release via Cleanup Thread' do
    it 'deletes keys after 5 minutes of total expiry' do
      key_id = JSON.parse(post('/generate').body)['key_id']
      expect($key_manager.total_keys_count).to eq(1)

      Timecop.travel(Time.now + KeyManager::KEY_INITIAL_EXPIRY_SECONDS + 0.5) do # Past 5 mins + buffer
        $key_manager.perform_cleanup # Explicitly trigger cleanup. No sleep needed.
        expect($key_manager.total_keys_count).to eq(0)
        expect($key_manager.key_status(key_id)).to be_nil
      end
    end

    # Fix for Failure 1 (app_spec.rb)
    it 'auto-releases blocked keys after 60 seconds if E3 is not called' do
      key_id = JSON.parse(post('/generate').body)['key_id']
      get '/key' # Block the key
      # Capture the precise `blocked_at` time *from the key object itself*.
      blocked_at_time = $key_manager.instance_variable_get(:@keys)[key_id].blocked_at

      expect($key_manager.key_status(key_id)).to eq(:blocked)
      expect($key_manager.available_keys_count).to eq(0)

      # Travel time should be relative to `blocked_at_time`. Add a small buffer to ensure `> 60`
      Timecop.travel(blocked_at_time + KeyManager::KEY_BLOCKED_AUTO_RELEASE_SECONDS + 1.0) do
        $key_manager.perform_cleanup # Explicitly trigger cleanup.
        expect($key_manager.key_status(key_id)).to eq(:available) # Should now be available
        expect($key_manager.available_keys_count).to eq(1)
        key_obj = $key_manager.instance_variable_get(:@keys)[key_id]
        expect(key_obj.expires_at).to be_within(1).of(Time.now + KeyManager::KEY_INITIAL_EXPIRY_SECONDS)
      end
    end

    it 'does not delete keys that are kept alive' do
      key_id = JSON.parse(post('/generate').body)['key_id']
      expect($key_manager.total_keys_count).to eq(1)

      Timecop.travel(Time.now + KeyManager::KEY_INITIAL_EXPIRY_SECONDS / 2) do
        post "/keep_alive/#{key_id}" # Keep it alive halfway
      end

      Timecop.travel(Time.now + KeyManager::KEY_INITIAL_EXPIRY_SECONDS + 0.5) do # Original expiry plus buffer
        $key_manager.perform_cleanup # Explicitly trigger cleanup.
        expect($key_manager.total_keys_count).to eq(1) # Should still exist
        expect($key_manager.key_status(key_id)).to eq(:available) # Should still be available
      end
    end
  end
end
