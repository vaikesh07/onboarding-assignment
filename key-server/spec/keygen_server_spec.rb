require_relative '../keygen_server'

describe KeygenServer do
    describe "instance created" do
        before :all do
            @server = KeygenServer.new
        end
        it "test server object should be creted from KeyServer class" do
            expect(@server).not_to be_nil
            expect(@server).to be_instance_of(KeygenServer)
        end
        it "should not have keys, available_keys and deleted_keys" do
            expect(@server.keys.count).to eq(0)
            expect(@server.available_keys.count).to eq(0)
            expect(@server.deleted_keys.count).to eq(0)
        end
    end
    describe "random_key" do
        before :all do
            @server = KeygenServer.new
        end
        it "should return a string of size 12" do
            expect(@server.random_key.length).to eq(12)
        end
    end
    describe "generate_keys" do
        before :all do
            @server = KeygenServer.new
        end
        it "should return return 5 active keys if generated for the first time" do
            expect(@server.generate_keys(5).length).to eq(5)
            expect(@server.keys.count).to eq(5)
            expect(@server.available_keys.count).to eq(5)
            expect(@server.deleted_keys.count).to eq(0)
        end
        it "should return return 10 active keys if 5 generated for the second time" do
            expect(@server.generate_keys(5).length).to eq(10)
            expect(@server.keys.count).to eq(10)
            expect(@server.available_keys.count).to eq(10)
            expect(@server.deleted_keys.count).to eq(0)
        end
        it "should have expiry date in future for every generated keys" do
            current_time = Time.now
            is_every_expiry_future = @server.keys.values.all? {|value|
                value['expiry'] > Time.now
            }
            expect(is_every_expiry_future).to be true 
        end
    end
    describe "get_available_key" do
        before :all do
            @server = KeygenServer.new
        end
        it "should return nil if no keys generated / available" do
            expect(@server.get_available_key).to be_nil
            expect(@server.available_keys.count).to eq(0)
            expect(@server.keys.count).to eq(0)
        end
        it "should return a string after generate_keys called" do
            @server.generate_keys(1)
            expect(@server.available_keys.count).to eq(1)
            expect(@server.get_available_key).to be_instance_of(String)
            expect(@server.available_keys.count).to eq(0)
            expect(@server.keys.count).to eq(1)
        end
        it "should return nil if all the keys assigned" do
            expect(@server.get_available_key).to be_nil
            expect(@server.keys.count).to eq(1)
            expect(@server.available_keys.count).to eq(0)
        end
        it "should block the key for one minute" do
            @server.generate_keys(1)
            key = @server.get_available_key
            expect(@server.keys[key]['blocked_till']).to be < (Time.now + 61)
        end
    end
    describe "unblock_key" do
        before :all do
            @server = KeygenServer.new
            @server.generate_keys(1)
        end
        it "should unblock the key after it is assigned once" do
            blocked_key = @server.get_available_key
            expect(@server.available_keys.count).to eq(0)
            expect(@server.unblock_key(blocked_key)).not_to be_nil
            expect(@server.keys[blocked_key]['blocked_till']).to be_nil
        end
        it "should make the key available again for get_available_key" do
            expect(@server.available_keys.count).to eq(1)
            expect(@server.get_available_key).to be_instance_of(String)
        end
        it "should only unblock the key which is blocked" do
            expect(@server.unblock_key('random_key')).to be_nil
        end
    end
    describe "delete_key" do
        before :all do
            @server = KeygenServer.new
            @server.generate_keys(1)
        end
        it "should delete the key and make it unavailable" do
            key = @server.get_available_key
            @server.unblock_key(key)
            expect(@server.delete_key(key)).not_to be_nil
            expect(@server.get_available_key).to be_nil
            expect(@server.keys.count).to eq(0)
            expect(@server.available_keys.count).to eq(0)
            expect(@server.deleted_keys.count).to eq(1)
        end
        it "should delete return nil for random keys" do
            expect(@server.delete_key('random_key')).to be_nil
        end
    end
    describe "keep_alive_key" do
        before :all do
            @server = KeygenServer.new
            @server.generate_keys(1)
        end
        it "should increase the expiry time for a key" do
            key = @server.get_available_key
            previous_expiry_time = @server.keys[key]['expiry']
            expect(@server.keep_alive_key(key)).not_to be_nil
            new_expiry_time = @server.keys[key]['expiry']
            is_new_expiry_greater = new_expiry_time > previous_expiry_time
            expect(is_new_expiry_greater).to be true 
        end
    end
end 