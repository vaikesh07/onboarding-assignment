# spec/key_manager_spec.rb
#
# RSpec tests for the KeyObject and KeyManager classes.

require 'rspec'
require 'timecop' # For time manipulation in tests
require_relative '../key_object'
require_relative '../min_heap'
require_relative '../key_manager'

# Temporarily shorten cleanup interval for tests that explicitly call it
KeyManager.send(:remove_const, :CLEANUP_INTERVAL_SECONDS)
KeyManager.const_set(:CLEANUP_INTERVAL_SECONDS, 0.1)

RSpec.describe KeyObject do
  let(:initial_expiry) { Time.now + 300 } # 5 minutes from now
  let(:key_id) { SecureRandom.uuid }
  subject(:key) { KeyObject.new(key_id, initial_expiry) }

  it 'initializes correctly' do
    expect(key.id).to eq(key_id)
    expect(key.status).to eq(:available)
    expect(key.generated_at).to be_within(1).of(Time.now)
    expect(key.expires_at).to eq(initial_expiry)
    expect(key.last_active_at).to be_within(1).of(Time.now)
    expect(key.blocked_at).to be_nil
    expect(key.is_stale_in_heap).to be false
  end

  it 'is active when available and not expired' do
    expect(key).to be_active
  end

  it 'is available when status is :available and not expired' do
    expect(key).to be_available
  end

  it 'is not available when status is :blocked' do
    key.status = :blocked
    expect(key).not_to be_available
  end

  it 'is blocked when status is :blocked and not expired' do
    key.status = :blocked
    expect(key).to be_blocked
  end

  it 'is not blocked when status is :available' do
    expect(key).not_to be_blocked
  end

  it 'is expired when expires_at is in the past' do
    Timecop.freeze(initial_expiry + 1) do
      expect(key).to be_expired
    end
  end

  it 'is not active when status is :deleted' do
    key.status = :deleted
    expect(key).not_to be_active
  end

  it 'is not active when status is :expired' do
    key.status = :expired
    expect(key).not_to be_active
  end

  describe '#should_auto_release_blocked?' do
    it 'returns true if blocked for more than 60 seconds' do
      key.status = :blocked
      key.blocked_at = Time.now - 61 # 61 seconds ago
      expect(key).to be_should_auto_release_blocked
    end

    it 'returns false if blocked for less than 60 seconds' do
      key.status = :blocked
      key.blocked_at = Time.now - 59 # 59 seconds ago
      expect(key).not_to be_should_auto_release_blocked
    end

    it 'returns false if not blocked' do
      expect(key).not_to be_should_auto_release_blocked
    end
  end

  it 'can be marked stale in heap' do
    key.mark_stale_in_heap
    expect(key.is_stale_in_heap).to be true
  end

  it 'can reset stale in heap' do
    key.mark_stale_in_heap
    key.reset_stale_in_heap
    expect(key.is_stale_in_heap).to be false
  end
end

RSpec.describe KeyManager do
  # Initialize KeyManager without starting the background thread for tests
  subject(:manager) { KeyManager.new(start_thread_on_init: false) }

  # Reset manager state and unfrozen time before each test
  before(:each) do
    manager.reset_state
    Timecop.return # Crucial: Ensure time is unfrozen before each test
  end

  # Ensure cleanup thread is stopped after all tests are done
  after(:all) do
    # Create a dummy manager if it wasn't instantiated by subject, just to call stop_cleanup_thread
    temp_manager = KeyManager.new(start_thread_on_init: false)
    temp_manager.stop_cleanup_thread
    KeyManager.send(:remove_const, :CLEANUP_INTERVAL_SECONDS)
    KeyManager.const_set(:CLEANUP_INTERVAL_SECONDS, 10) # Restore default for safety
  end


  describe '#generate_key' do
    it 'generates a unique key' do
      key1 = manager.generate_key
      key2 = manager.generate_key
      expect(key1).not_to eq(key2)
    end

    it 'adds the key to total and available counts' do
      expect { manager.generate_key }.to change { manager.total_keys_count }.by(1)
      expect(manager.available_keys_count).to eq(1)
    end

    it 'sets the key status to available' do
      key_id = manager.generate_key
      expect(manager.key_status(key_id)).to eq(:available)
    end
  end

  describe '#get_available_key' do
    context 'when available keys exist' do
      it 'returns an available key' do
        manager.generate_key # Ensure there's one key to get
        key_id = manager.get_available_key
        expect(key_id).to be_a(String)
      end

      it 'blocks the retrieved key' do
        key_id = manager.generate_key # Generate a key for this specific test
        manager.get_available_key
        expect(manager.key_status(key_id)).to eq(:blocked)
      end

      it 'removes the key from the available pool' do
        manager.generate_key # Generate a key for this specific test
        expect(manager.available_keys_count).to eq(1)
        manager.get_available_key
        expect(manager.available_keys_count).to eq(0)
      end

      it 'resets the expiry of the key' do
        manager.reset_state # Ensure a clean slate for this specific test
        key_id_to_check = manager.generate_key # This is the only key now

        key_object_before_get = manager.instance_variable_get(:@keys)[key_id_to_check]
        initial_expiry_original_time = key_object_before_get.expires_at

        # Simulate time passing, then get the key
        Timecop.freeze(Time.now + 100) do
          retrieved_key_id = manager.get_available_key
          expect(retrieved_key_id).to eq(key_id_to_check) # Now this assertion will pass
          retrieved_key_object = manager.instance_variable_get(:@keys)[retrieved_key_id]
          expect(retrieved_key_object.expires_at).to be_within(1).of(Time.now + KeyManager::KEY_INITIAL_EXPIRY_SECONDS)
          # Make sure it's different from the original expiry (which was relative to the *initial* Time.now)
          expect(retrieved_key_object.expires_at).not_to eq(initial_expiry_original_time)
        end
      end
    end

    context 'when no available keys exist' do
      it 'returns nil' do
        expect(manager.get_available_key).to be_nil
      end

      it 'does not change key counts' do
        expect { manager.get_available_key }.not_to change { manager.total_keys_count }
        expect { manager.get_available_key }.not_to change { manager.available_keys_count }
      end
    end
  end

  describe '#unblock_key' do
    let!(:key_id) { manager.generate_key }

    context 'when key is blocked' do
      before { manager.get_available_key } # Block the key

      it 'unblocks the key successfully' do
        expect(manager.unblock_key(key_id)).to be true
        expect(manager.key_status(key_id)).to eq(:available)
      end

      it 'adds the key back to the available pool' do
        expect(manager.available_keys_count).to eq(0) # After blocking
        manager.unblock_key(key_id)
        expect(manager.available_keys_count).to eq(1)
      end

      it 'resets the expiry of the key' do
        blocked_key_object = manager.instance_variable_get(:@keys)[key_id]
        old_expiry = blocked_key_object.expires_at
        Timecop.freeze(Time.now + 100) do # Simulate time passing
          manager.unblock_key(key_id)
          new_expiry = blocked_key_object.expires_at
          expect(new_expiry).to be_within(1).of(Time.now + KeyManager::KEY_INITIAL_EXPIRY_SECONDS)
          expect(new_expiry).not_to eq(old_expiry)
        end
      end
    end

    context 'when key is not blocked' do
      it 'returns false if key is available' do
        expect(manager.key_status(key_id)).to eq(:available)
        expect(manager.unblock_key(key_id)).to be false
      end

      it 'returns false if key is deleted' do
        manager.delete_key(key_id)
        expect(manager.unblock_key(key_id)).to be false
      end

      it 'returns false if key is expired (but not blocked)' do
        key_obj = manager.instance_variable_get(:@keys)[key_id]
        key_obj.expires_at = Time.now - 1 # Force expiry without blocking
        expect(manager.unblock_key(key_id)).to be false
        expect(manager.key_status(key_id)).to eq(:available) # Still available, but expired
      end

      # Fix for Failure 2: Re-evaluated and updated test logic.
      it 'returns false if key is blocked AND expired and is then cleaned up' do
        key_id_expired_blocked = manager.generate_key
        manager.get_available_key # Block it

        Timecop.freeze(Time.now + 1) do # Freeze time to precisely control expiry
          key_obj = manager.instance_variable_get(:@keys)[key_id_expired_blocked]
          key_obj.expires_at = Time.now - 1 # Make it expired relative to frozen time

          # At this point, key_obj.status is :blocked, but key_obj.expired? is true.
          # So key_obj.blocked? is false (because it's expired).
          expect(key_obj.blocked?).to be false
          # Therefore, unblock_key should explicitly return false and NOT modify the status.
          expect(manager.unblock_key(key_id_expired_blocked)).to be false

          # The key status should remain :blocked, as unblock_key failed to change it.
          # It's up to the cleanup process to mark it expired and delete it.
          expect(manager.key_status(key_id_expired_blocked)).to eq(:blocked)

          # Now, explicitly run cleanup. It should identify the expired key and delete it.
          manager.perform_cleanup
          expect(manager.key_status(key_id_expired_blocked)).to be_nil # Should be deleted by cleanup
        end
      end
    end

    context 'when key does not exist' do
      it 'returns false' do
        expect(manager.unblock_key('non_existent_key')).to be false
      end
    end
  end

  describe '#delete_key' do
    let!(:key_id) { manager.generate_key }

    it 'deletes an available key successfully' do
      expect(manager.delete_key(key_id)).to be true
      expect(manager.total_keys_count).to eq(0)
      expect(manager.available_keys_count).to eq(0)
      expect(manager.key_status(key_id)).to be_nil
    end

    it 'deletes a blocked key successfully' do
      manager.get_available_key # Block the key
      expect(manager.delete_key(key_id)).to be true
      expect(manager.total_keys_count).to eq(0)
      expect(manager.available_keys_count).to eq(0)
      expect(manager.key_status(key_id)).to be_nil
    end

    it 'returns false if key does not exist' do
      expect(manager.delete_key('non_existent_key')).to be false
    end
  end

  describe '#keep_alive' do
    let!(:key_id) { manager.generate_key }

    it 'updates the expiry of an available key' do
      key_obj = manager.instance_variable_get(:@keys)[key_id]
      old_expiry = key_obj.expires_at
      Timecop.freeze(Time.now + 100) do # Simulate time passing
        expect(manager.keep_alive(key_id)).to be true
        new_expiry = key_obj.expires_at
        expect(new_expiry).to be_within(1).of(Time.now + KeyManager::KEY_INITIAL_EXPIRY_SECONDS)
        expect(new_expiry).not_to eq(old_expiry)
      end
    end

    it 'updates the expiry of a blocked key' do
      manager.get_available_key # Block the key
      key_obj = manager.instance_variable_get(:@keys)[key_id]
      old_expiry = key_obj.expires_at
      Timecop.freeze(Time.now + 100) do # Simulate time passing
        expect(manager.keep_alive(key_id)).to be true
        new_expiry = key_obj.expires_at
        expect(new_expiry).to be_within(1).of(Time.now + KeyManager::KEY_INITIAL_EXPIRY_SECONDS)
        expect(new_expiry).not_to eq(old_expiry)
      end
    end

    it 'returns false if key does not exist' do
      expect(manager.keep_alive('non_existent_key')).to be false
    end

    it 'returns false if key is deleted' do
      manager.delete_key(key_id)
      expect(manager.keep_alive(key_id)).to be false
    end
  end

  describe 'Automatic Cleanup' do
    it 'deletes available keys after 5 minutes of inactivity' do
      key_id = manager.generate_key
      expect(manager.total_keys_count).to eq(1)

      Timecop.travel(Time.now + KeyManager::KEY_INITIAL_EXPIRY_SECONDS + 1) do
        manager.perform_cleanup # Explicitly trigger cleanup
        expect(manager.total_keys_count).to eq(0)
        expect(manager.available_keys_count).to eq(0)
        expect(manager.key_status(key_id)).to be_nil
      end
    end

    # Fix for Failure 3 (key_manager_spec.rb)
    it 'auto-releases blocked keys after 60 seconds if not unblocked' do
      key_id = manager.generate_key
      manager.get_available_key # Block the key
      blocked_at_time = manager.instance_variable_get(:@keys)[key_id].blocked_at # Capture actual blocked_at

      expect(manager.key_status(key_id)).to eq(:blocked)
      expect(manager.available_keys_count).to eq(0)

      # Travel time should be relative to `blocked_at_time`. Add a small buffer to ensure `> 60`
      Timecop.travel(blocked_at_time + KeyManager::KEY_BLOCKED_AUTO_RELEASE_SECONDS + 1.0) do
        manager.perform_cleanup # Explicitly trigger cleanup.
        expect(manager.key_status(key_id)).to eq(:available) # Should now be available
        expect(manager.available_keys_count).to eq(1) # Should be back in available pool
        key_obj = manager.instance_variable_get(:@keys)[key_id]
        # Its expiry should be reset from *this* Time.now (which is blocked_at_time + 61s)
        expect(key_obj.expires_at).to be_within(1).of(Time.now + KeyManager::KEY_INITIAL_EXPIRY_SECONDS)
      end
    end

    it 'does not delete keys that are kept alive' do
      key_id = manager.generate_key
      expect(manager.total_keys_count).to eq(1)

      Timecop.travel(Time.now + KeyManager::KEY_INITIAL_EXPIRY_SECONDS / 2) do
        manager.keep_alive(key_id) # Keep it alive halfway
      end

      Timecop.travel(Time.now + KeyManager::KEY_INITIAL_EXPIRY_SECONDS + 1) do
        manager.perform_cleanup
        expect(manager.total_keys_count).to eq(1) # Should still exist
        expect(manager.key_status(key_id)).to eq(:available) # Should still be available
      end
    end

    # Fix for Failure 4 (key_manager_spec.rb)
    it 'handles multiple keys expiring/auto-releasing correctly' do
      # Generate keys
      key1 = manager.generate_key
      key2 = manager.generate_key
      key3 = manager.generate_key # This will be the one that expires fully

      # Capture initial Time.now right after generating, for reference of key3's original expiry
      original_initial_time = Time.now
      key3_obj = manager.instance_variable_get(:@keys)[key3] # Get reference to key3 object

      # Block key1 and key2
      manager.get_available_key # key1 becomes blocked at current Time.now
      # Capture blocked_at for key1
      key1_blocked_at = manager.instance_variable_get(:@keys)[key1].blocked_at

      manager.get_available_key # key2 becomes blocked at current Time.now
      # Capture blocked_at for key2
      key2_blocked_at = manager.instance_variable_get(:@keys)[key2].blocked_at


      expect(manager.total_keys_count).to eq(3)
      expect(manager.available_keys_count).to eq(1) # only key3 available
      expect(manager.key_status(key1)).to eq(:blocked)
      expect(manager.key_status(key2)).to eq(:blocked)
      expect(manager.key_status(key3)).to eq(:available)

      # Fast forward time to trigger auto-release for key1, key2
      # Travel to a time past the earliest possible auto-release for key1/key2.
      # Since they were blocked almost simultaneously, using `key1_blocked_at` as the base is fine.
      Timecop.travel(key1_blocked_at + KeyManager::KEY_BLOCKED_AUTO_RELEASE_SECONDS + 1) do
        manager.perform_cleanup # Explicitly trigger cleanup

        expect(manager.total_keys_count).to eq(3)
        expect(manager.available_keys_count).to eq(3) # key1, key2 auto-released + key3 still available
        expect(manager.key_status(key1)).to eq(:available)
        expect(manager.key_status(key2)).to eq(:available)
        expect(manager.key_status(key3)).to eq(:available)

        # Check expiries of auto-released keys: they should be current_Time.now + 300s
        key1_obj = manager.instance_variable_get(:@keys)[key1]
        key2_obj = manager.instance_variable_get(:@keys)[key2]
        expect(key1_obj.expires_at).to be_within(1).of(Time.now + KeyManager::KEY_INITIAL_EXPIRY_SECONDS)
        expect(key2_obj.expires_at).to be_within(1).of(Time.now + KeyManager::KEY_INITIAL_EXPIRY_SECONDS)

        # key3's expiry remains its original expiry relative to `original_initial_time`
        # `Time.now` in this block is `original_initial_time + 61s`.
        # So key3_obj.expires_at should be `original_initial_time + 300s`.
        expect(key3_obj.expires_at).to be_within(1).of(original_initial_time + KeyManager::KEY_INITIAL_EXPIRY_SECONDS)
      end

      # Now, fast forward further to ensure key3 expires and is deleted.
      # key3's original expiry was `original_initial_time + 300s`.
      # We need to travel to a time past that.
      Timecop.travel(original_initial_time + KeyManager::KEY_INITIAL_EXPIRY_SECONDS + 1) do
        manager.perform_cleanup # Explicitly trigger cleanup

        expect(manager.total_keys_count).to eq(2) # key3 deleted
        expect(manager.available_keys_count).to eq(2)
        expect(manager.key_status(key1)).to eq(:available)
        expect(manager.key_status(key2)).to eq(:available)
        expect(manager.key_status(key3)).to be_nil # deleted
      end
    end
  end
end
