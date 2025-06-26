# key_manager.rb
#
# Implements the KeyManager class, which is responsible for generating,
# managing the state, and cleaning up API keys according to specified rules.
# It uses a MinHeap for efficient expiry management and a Set for available keys.

require 'securerandom' # For generating unique API keys (UUIDs)
require 'set'          # For O(1) operations on available key IDs
require 'thread'       # For managing the background cleanup thread
require 'monitor'      # For thread-safe access to shared data structures

# Include the KeyObject and MinHeap classes
require_relative 'key_object'
require_relative 'min_heap'

class KeyManager
  # Constants for key expiry durations
  KEY_INITIAL_EXPIRY_SECONDS = 5 * 60 # 5 minutes
  KEY_BLOCKED_AUTO_RELEASE_SECONDS = 60 # 60 seconds for blocked keys to auto-release

  # Cleanup thread interval in seconds
  CLEANUP_INTERVAL_SECONDS = 10 # Periodically run cleanup every 10 seconds

  # Initializes a new KeyManager.
  # @param start_thread_on_init [Boolean] If true, the background cleanup thread
  #                                       will be started immediately. Default false for testing.
  def initialize(start_thread_on_init: false)
    @keys = {}
    @available_key_ids = Set.new
    @expiry_heap = MinHeap.new # Stores [timestamp_for_next_action, key_id]
    @mutex = Monitor.new
    @cond = @mutex.new_cond

    @running = false
    @cleanup_thread = nil

    start_cleanup_thread if start_thread_on_init
  end

  # Private helper to determine the next cleanup timestamp for a key
  # This is the timestamp that goes into the min-heap.
  # It's the EARLIEST of its true expiry or its blocked auto-release time.
  private def calculate_next_cleanup_timestamp(key)
    if key.status == :blocked && key.blocked_at
      # For a blocked key, the next action could be auto-release or full expiry.
      # The heap should prioritize the earliest of these.
      blocked_auto_release_time = key.blocked_at + KEY_BLOCKED_AUTO_RELEASE_SECONDS
      # Return the earliest of its general expiry OR its auto-release time
      [key.expires_at.to_f, blocked_auto_release_time.to_f].min
    else
      # For available keys, it's just their expiry time.
      key.expires_at.to_f
    end
  end

  # Public API Methods (Endpoints)

  # E1: Generates a new API key.
  # @complexity O(1)
  def generate_key
    @mutex.synchronize do
      key_id = SecureRandom.uuid
      initial_expiry = Time.now + KEY_INITIAL_EXPIRY_SECONDS
      key = KeyObject.new(key_id, initial_expiry)

      @keys[key_id] = key
      @available_key_ids.add(key_id)
      # Heap entry based on its expiry time (5 min)
      @expiry_heap.insert([calculate_next_cleanup_timestamp(key), key_id])

      puts "[KeyManager] Generated key: #{key_id} (Expires: #{key.expires_at})"
      key_id
    end
  end

  # E2: Retrieves an available key.
  # @complexity O(1)
  def get_available_key
    @mutex.synchronize do
      return nil if @available_key_ids.empty?

      key_id = @available_key_ids.first

      key = @keys[key_id]
      return nil unless key

      key.status = :blocked
      key.blocked_at = Time.now # Set blocked_at timestamp
      key.last_active_at = Time.now
      key.expires_at = Time.now + KEY_INITIAL_EXPIRY_SECONDS # Overall 5 min expiry from now

      key.mark_stale_in_heap # Mark previous entry stale
      # Heap entry based on the auto-release time (60 sec) for blocked key
      @expiry_heap.insert([calculate_next_cleanup_timestamp(key), key_id])

      @available_key_ids.delete(key_id)

      puts "[KeyManager] Served key: #{key_id} (Blocked)"
      key_id
    end
  end

  # E3: Unblocks a key.
  # @complexity O(1)
  def unblock_key(key_id)
    @mutex.synchronize do
      key = @keys[key_id]
      return false unless key

      # Can only unblock if currently in a blocked state and not expired.
      # key.blocked? implies !key.expired?
      if key.blocked?
        key.status = :available
        key.blocked_at = nil # Clear blocked timestamp
        key.last_active_at = Time.now
        key.expires_at = Time.now + KEY_INITIAL_EXPIRY_SECONDS # Reset expiry to 5 min from now

        key.mark_stale_in_heap # Mark previous entry stale
        # Heap entry based on its new expiry time (5 min)
        @expiry_heap.insert([calculate_next_cleanup_timestamp(key), key_id])

        @available_key_ids.add(key_id)
        puts "[KeyManager] Unblocked key: #{key_id} (New expiry: #{key.expires_at})"
        true
      else
        puts "[KeyManager] Failed to unblock key: #{key_id} (Not blocked or already expired)"
        false
      end
    end
  end

  # E4: Deletes a key.
  # @complexity O(1)
  def delete_key(key_id)
    @mutex.synchronize do
      key = @keys.delete(key_id)
      return false unless key

      @available_key_ids.delete(key_id)
      key.status = :deleted # Mark as deleted for safety
      key.mark_stale_in_heap # Mark heap entry stale as key is gone

      puts "[KeyManager] Deleted key: #{key_id}"
      true
    end
  end

  # E5: Keep-alive for a key.
  # @complexity O(1)
  def keep_alive(key_id)
    @mutex.synchronize do
      key = @keys[key_id]
      return false unless key && key.active?

      key.last_active_at = Time.now
      # Extend overall expiry by 5 minutes from now.
      key.expires_at = Time.now + KEY_INITIAL_EXPIRY_SECONDS

      key.mark_stale_in_heap # Mark previous entry stale
      # Re-insert with its new cleanup timestamp (could be 60s if blocked, or 5min if available)
      @expiry_heap.insert([calculate_next_cleanup_timestamp(key), key_id])

      puts "[KeyManager] Keep-alive for key: #{key_id} (New expiry: #{key.expires_at})"
      true
    end
  end

  # --- Test/Internal Management Methods ---

  # Starts the background cleanup thread.
  def start_cleanup_thread
    @mutex.synchronize do
      return if @running
      @running = true
      @cleanup_thread = Thread.new { run_cleanup_loop }
      puts "[KeyManager] Background cleanup thread started."
    end
  end

  # Stops the background cleanup thread gracefully.
  def stop_cleanup_thread
    @mutex.synchronize do
      return unless @running
      @running = false
      @cond.signal # Wake up the cleanup thread if it's waiting
    end
    @cleanup_thread.join if @cleanup_thread && @cleanup_thread.alive?
    @cleanup_thread = nil
    puts "[KeyManager] Background cleanup thread stopped."
  end

  # Resets the internal state of the KeyManager for testing purposes.
  def reset_state
    @mutex.synchronize do
      @keys.clear
      @available_key_ids.clear
      @expiry_heap = MinHeap.new
      puts "[KeyManager] Manager state reset."
    end
  end

  # Performs the actual key cleanup. Made public for explicit calling in tests.
  def perform_cleanup
    # puts "[KeyManager] Running cleanup..." # Uncomment for debugging verbose output
    keys_to_process_for_final_deletion = []

    @mutex.synchronize do
      # Process all items at the head of the heap that are due for action
      while (min_entry = @expiry_heap.peek) && (min_entry[0] <= Time.now.to_f)
        _timestamp, key_id = @expiry_heap.extract_min
        key = @keys[key_id]

        # Skip if key was deleted/changed by another thread/operation, or if this heap entry is stale
        next unless key
        if key.is_stale_in_heap
          key.reset_stale_in_heap # Reset the stale flag now that we've seen this stale entry
          next # Skip this stale entry
        end

        # Crucial order of checks: Expired keys should be deleted first.
        # A key can be both :blocked and expired if its 5-min overall expiry passes while it's blocked.
        if key.expired?
          # puts "[KeyManager] Expired key identified for deletion: #{key_id}"
          key.status = :expired # Mark for final deletion
          keys_to_process_for_final_deletion << key_id
        elsif key.status == :blocked && key.should_auto_release_blocked?
          # This key is blocked, has passed its 60-second auto-release threshold,
          # AND is NOT yet expired its overall 5-minute validity.
          # puts "[KeyManager] Blocked key auto-releasing: #{key_id}"
          # Calling unblock_key will update its status, clear blocked_at, reset expires_at,
          # and re-insert a new, non-stale entry into the heap based on its new (5-min) expiry.
          unblock_key(key_id)
        end
        # Any key processed from the heap should be immediately marked stale,
        # or have its status change (which implies a new heap entry and marking old stale),
        # so this next_if condition ensures we don't re-process the same event or skip valid ones.
      end
    end

    # Process collected keys for permanent deletion (outside the main heap loop for clarity)
    keys_to_process_for_final_deletion.each do |key_id|
      @mutex.synchronize do
        key = @keys[key_id]
        # Only delete if it's still present and truly marked as :expired
        if key && key.status == :expired
          delete_key_internal(key_id)
        end
      end
    end
    # puts "[KeyManager] Cleanup finished." # Uncomment for debugging verbose output
  end

  private

  # The main loop for the cleanup thread
  def run_cleanup_loop
    @mutex.synchronize do
      while @running
        @cond.wait(CLEANUP_INTERVAL_SECONDS)
        break unless @running

        perform_cleanup
      end
    end
  end

  # Internal helper for deletion
  def delete_key_internal(key_id)
    key = @keys.delete(key_id)
    @available_key_ids.delete(key_id) if key
  end

  public # For testing access
  # For testing purposes
  def key_status(key_id)
    @mutex.synchronize do
      key = @keys[key_id]
      key ? key.status : nil
    end
  end

  # For testing purposes
  def available_keys_count
    @mutex.synchronize do
      @available_key_ids.size
    end
  end

  # For testing purposes
  def total_keys_count
    @mutex.synchronize do
      @keys.size
    end
  end
end
