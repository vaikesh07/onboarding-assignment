# key_object.rb
#
# Defines the KeyObject class, representing an individual API key with its state
# and associated timestamps.

class KeyObject
    # Unique identifier for the API key.
    attr_reader :id
    # Current status of the key: :available, :blocked, :deleted, :expired.
    attr_accessor :status
    # Timestamp when the key was initially generated.
    attr_reader :generated_at
    # Absolute timestamp when the key is considered expired.
    attr_accessor :expires_at
    # Timestamp of the last successful interaction (keep-alive, get, unblock).
    attr_accessor :last_active_at
    # Timestamp when the key was last moved to the :blocked state.
    # Used for the 60-second auto-release rule for blocked keys.
    attr_accessor :blocked_at
    # A flag indicating if this key's entry in the expiry heap is potentially stale.
    # This avoids expensive updates/removals in the heap by just re-inserting
    # a new expiry and marking the old one as stale. Cleanup will ignore stale ones.
    attr_accessor :is_stale_in_heap
  
    # Initializes a new KeyObject.
    # @param id [String] The unique ID for the key.
    # @param initial_expiry [Time] The initial expiration time.
    def initialize(id, initial_expiry)
      @id = id
      @status = :available # Newly generated keys are available
      @generated_at = Time.now
      @expires_at = initial_expiry
      @last_active_at = Time.now # Initially active upon generation
      @blocked_at = nil # Not blocked initially
      @is_stale_in_heap = false # Not stale initially
    end
  
    # Checks if the key is currently active (not expired or deleted).
    # @return [Boolean] True if active, false otherwise.
    def active?
      @status != :deleted && @status != :expired
    end
  
    # Checks if the key is currently available to be served.
    # @return [Boolean] True if available, false otherwise.
    def available?
      @status == :available && !expired?
    end
  
    # Checks if the key is currently blocked (in use).
    # @return [Boolean] True if blocked, false otherwise.
    def blocked?
      @status == :blocked && !expired?
    end
  
    # Checks if the key has expired based on its expires_at timestamp.
    # @return [Boolean] True if expired, false otherwise.
    def expired?
      @expires_at <= Time.now
    end
  
    # Checks if a blocked key should be automatically unblocked due to timeout.
    # A blocked key auto-releases after 60 seconds if not unblocked by E3.
    # @return [Boolean] True if it should auto-release, false otherwise.
    def should_auto_release_blocked?
      @status == :blocked && @blocked_at && (Time.now - @blocked_at >= 60)
    end
  
    # Marks the key as stale in the heap.
    def mark_stale_in_heap
      @is_stale_in_heap = true
    end
  
    # Resets the stale flag for heap.
    def reset_stale_in_heap
      @is_stale_in_heap = false
    end
  end
  