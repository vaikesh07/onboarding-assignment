# app.rb
#
# Sinatra application for the API Key Management server.
# Defines the HTTP endpoints and interacts with the KeyManager.

require 'sinatra'
require 'json' # For JSON responses
require_relative 'key_manager' # Load the KeyManager class

# Create a global instance of KeyManager.
# This ensures that all requests interact with the same key management system.
# The cleanup thread starts automatically on initialization.
$key_manager = KeyManager.new(start_thread_on_init: true) # Explicitly start thread for app

# Configure Sinatra for development
set :bind, '0.0.0.0' # Listen on all interfaces
set :port, 4567     # Default Sinatra port

# Disable Rack protection for simplicity in this example (can be re-enabled for production)
set :protection, false

# --- Helper Methods ---

# Standard JSON response for success
def success_response(data = {}, status = 200)
  content_type :json
  status status
  data.to_json
end

# Standard JSON response for errors
def error_response(message, status = 400)
  content_type :json
  status status
  { error: message }.to_json
end

# --- API Endpoints ---

# E1: POST /generate
# Generates a new API key with a 5-minute expiry.
post '/generate' do
  begin
    key_id = $key_manager.generate_key
    success_response(key_id: key_id)
  rescue StandardError => e
    error_response("Failed to generate key: #{e.message}", 500)
  end
end

# E2: GET /key
# Retrieves an available API key. The key becomes blocked.
# Returns 404 if no available key.
get '/key' do
  begin
    key_id = $key_manager.get_available_key
    if key_id
      success_response(key_id: key_id)
    else
      error_response("No available keys.", 404)
    end
  rescue StandardError => e
    error_response("Failed to get key: #{e.message}", 500)
  end
end

# E3: POST /unblock/:key_id
# Unblocks a previously blocked key, making it available again.
# Resets its expiry to 5 minutes from now.
post '/unblock/:key_id' do
  key_id = params[:key_id]
  begin
    if $key_manager.unblock_key(key_id)
      success_response(message: "Key '#{key_id}' unblocked successfully.")
    else
      error_response("Key '#{key_id}' not found or not in a blockable state.", 404)
    end
  rescue StandardError => e
    error_response("Failed to unblock key '#{key_id}': #{e.message}", 500)
  end
end

# E4: DELETE /delete/:key_id
# Deletes a key permanently.
delete '/delete/:key_id' do
  key_id = params[:key_id]
  begin
    if $key_manager.delete_key(key_id)
      status 204 # No Content for successful deletion
    else
      error_response("Key '#{key_id}' not found.", 404)
    end
  rescue StandardError => e
    error_response("Failed to delete key '#{key_id}': #{e.message}", 500)
  end
end

# E5: POST /keep_alive/:key_id
# Extends the expiry of an active key by 5 minutes.
post '/keep_alive/:key_id' do
  key_id = params[:key_id]
  begin
    if $key_manager.keep_alive(key_id)
      success_response(message: "Key '#{key_id}' keep-alive successful.")
    else
      error_response("Key '#{key_id}' not found or not active.", 404)
    end
  rescue StandardError => e
    error_response("Failed to keep alive key '#{key_id}': #{e.message}", 500)
  end
end

# No at_exit block here anymore. Thread management for the app
# would typically be handled by the web server (e.g., Rack/Puma/Unicorn)
# or via a dedicated shutdown signal handler in a more complex setup.

# Basic root route for testing if the server is running
get '/' do
  'API Key Management Server is running!'
end
