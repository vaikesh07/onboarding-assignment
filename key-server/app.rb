require 'sinatra'
require 'json'
require './keygen_server'
class KeygenRoutes < Sinatra::Application
    server = KeygenServer.new
    post '/key/generate' do
        data = JSON.parse(request.body.read)
        begin 
            int_count = Integer(data['count'])
            status 200
            server.generate_keys(int_count).to_a.to_s
        rescue ArgumentError => e
            status 400
            "Invalid Count Provided: '#{count}'"
        end 
    end
    get '/key' do
        key = server.get_available_key
        if key
            status 200
            key
        else
            status 404
            "No Key Available"
        end
    end
    patch '/key/unblock' do
        data = JSON.parse(request.body.read)
        key = data['key']
        unblocked_key = server.unblock_key key
        if unblocked_key
            status 200
            "#{key} unblocked"
        else
            status 400
            "Bad Request"
        end
    end
    delete '/key/:key' do |key|
        deleted_key = server.delete_key key
        if deleted_key
            status 200
            "#{key} deleted"
        else
            status 400
            "Bad Request"
        end
    end
    patch '/key/keep-alive' do
        data = JSON.parse(request.body.read)
        key = data['key']
        alive_key = server.keep_alive_key key
        if alive_key
            status 200
            "expiry increased for #{key}"
        else
            status 400
            "Bad Request"
        end
    end
    get '/*' do
        status 200
        %{
            Endpoints:<br/>
            1) [post: { :count }] /key/generate<br/>
            2) [get] /key<br/>
            3) [patch: { :key }] /key/unblock<br/>
            4) [patch: { :key }] /key/keep-alive<br/>
            5) [delete] /key/:key<br/>
        }
    end
end

KeygenRoutes.run!