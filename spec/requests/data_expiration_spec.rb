require 'rails_helper'

describe 'Data expiration command API', type: :request do
  describe 'KEYS in string and set' do
    it 'list all keys in string and set' do
      post '/commands', params: { command: "SET mystringkey 1" }
      post '/commands', params: { command: "SADD mysetkey 1 2 3" }
      post '/commands', params: { command: "KEYS" }
      
      expect(JSON.parse(response.body)).to eq (
        {
            'code' => 0,
            'keys' => ['mystringkey', 'mysetkey']
        }
      )
    end
  
    it 'list all keys in string only' do
      post '/commands', params: { command: "SET mystringkey 1" }
      post '/commands', params: { command: "SET mystringkey1 1" }
      post '/commands', params: { command: "KEYS" }
      
      expect(JSON.parse(response.body)).to eq (
        {
            'code' => 0,
            'keys' => ['mystringkey', 'mystringkey1']
        }
      )
    end

    it 'list all keys in set only' do
      post '/commands', params: { command: "SADD mysetkey 1" }
      post '/commands', params: { command: "SADD mysetkey1 1 abc d" }
      post '/commands', params: { command: "KEYS" }
      
      expect(JSON.parse(response.body)).to eq (
        {
            'code' => 0,
            'keys' => ['mysetkey', 'mysetkey1']
        }
      )
    end

    it 'list all keys but empty' do
      post '/commands', params: { command: "KEYS" }
      
      expect(JSON.parse(response.body)).to eq (
        {
            'code' => 0,
            'keys' => []
        }
      )
    end
  end

  describe 'DEL keys' do
    it 'DEL only one string key exist' do
      post '/commands', params: { command: "SET mykey 123" }
      post '/commands', params: { command: "SADD mysetkey 456 123" }
      post '/commands', params: { command: "DEL mykey" }
      
      expect(JSON.parse(response.body)).to eq (
        {
            'code' => 0,
            'message' => 1
        }
      )
    end

    it 'DEL only one set key exist' do
      post '/commands', params: { command: "SET mykey 123" }
      post '/commands', params: { command: "SADD mysetkey 456 123" }
      post '/commands', params: { command: "DEL mysetkey" }
      
      expect(JSON.parse(response.body)).to eq (
        {
            'code' => 0,
            'message' => 1
        }
      )
    end

    it 'DEL only one set key exist' do
      post '/commands', params: { command: "SET mykey 123" }
      post '/commands', params: { command: "SADD mysetkey 456 123" }
      post '/commands', params: { command: "DEL noexistkey" }
      
      expect(JSON.parse(response.body)).to eq (
        {
            'code' => 0,
            'message' => 0
        }
      )
    end

    it 'DEL argument passing invalid' do
      post '/commands', params: { command: "DEL noexistkey anotherkey" }

      expect(JSON.parse(response.body)).to eq (
        {
            'code' => 2,
            'message' => "ERROR: wrong number of arguments for 'del' command"
        }
      )
    end
  end
end
