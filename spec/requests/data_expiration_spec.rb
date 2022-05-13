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

    it 'list all keys but empty' do
      post '/commands', params: { command: "KEYS somethingkey" }
      
      expect(JSON.parse(response.body)).to eq (
        {
            'code' => 2,
            'message' => "ERROR: wrong number of arguments for 'keys' command"
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

  describe 'EXPIRE a key' do 
    describe 'EXPIRE key exist' do 
      it 'EXPIRE time for a new key' do
        post '/commands', params: { command: "SET key1 something"}
        post '/commands', params: { command: "EXPIRE key1 50"}

        expect(JSON.parse(response.body)).to eq (
          {
            'code' => 0,
            'value' => 1
          }
        )
      end

      it 'reEXPIRE time for a key' do
        post '/commands', params: { command: "SET key1 something"}
        post '/commands', params: { command: "EXPIRE key1 10"}
        sleep(5)
        post '/commands', params: { command: "EXPIRE key1 50"}

        expect(JSON.parse(response.body)).to eq (
          {
            'code' => 0,
            'value' => 1
          }
        )
      end
      
      it 'reEXPIRE time for a timeout key' do
        post '/commands', params: { command: "SET key1 something"}
        post '/commands', params: { command: "EXPIRE key1 10"}
        sleep(15)
        post '/commands', params: { command: "EXPIRE key1 50"}

        expect(JSON.parse(response.body)).to eq (
          {
            'code' => 0,
            'value' => 0
          }
        )
      end

      it 'EXPIRE a negative time for a key' do
        post '/commands', params: { command: "SET key1 something"}
        post '/commands', params: { command: "EXPIRE key1 -10"}

        expect(JSON.parse(response.body)).to eq (
          {
            'code' => 0,
            'value' => 1
          }
        )
      end
    end

    describe 'EXPIRE key not exist' do 
      it 'EXPIRE a positve number for a new key' do
        post '/commands', params: { command: "EXPIRE lam 50" }

        expect(JSON.parse(response.body)).to eq (
          {
            'code' => 0,
            'value' => 0
          }
        )
      end

      it 'EXPIRE a negative number for a new key' do
        post '/commands', params: { command: "EXPIRE lam -50" }

        expect(JSON.parse(response.body)).to eq (
          {
            'code' => 0,
            'value' => 0
          }
        )
      end
    end

    describe 'invalid argument passing' do
      it 'EXPIRE a negative number for a new key' do
        post '/commands', params: { command: "EXPIRE lam -50 70" }

        expect(JSON.parse(response.body)).to eq (
          {
            'code' => 2,
            'message' => "ERROR: wrong number of arguments for 'expire' command"
          }
        )
      end

      it 'argument is not a number' do
        post '/commands', params: { command: "EXPIRE lam something" }

        expect(JSON.parse(response.body)).to eq (
          {
            'code' => 5,
            'message' => "ERROR: value is not an integer or out of range"
          }
        )
      end
    end
  end

  describe 'TTL key'do

    describe 'a key exists' do
      it 'a key is not seted the time expiration' do
        post '/commands', params: { command: "SET mykey10 13" }
        post '/commands', params: { command: "TTL mykey10"}

        expect(JSON.parse(response.body)).to eq (
          {
            'code' => 0,
            'value' => -1
          }
        )
      end

      it 'a key is seted the time expiration' do
        post '/commands', params: { command: "SET mykey10 13" }
        post '/commands', params: { command: "EXPIRE mykey10 50"}
        post '/commands', params: { command: "TTL mykey10"}

        expect(JSON.parse(response.body)).to eq (
          {
            'code' => 0,
            'value' => 49
          }
        )
      end

      it 'a key still has the time expiration' do
        post '/commands', params: { command: "SET mykey10 13" }
        post '/commands', params: { command: "EXPIRE mykey10 5"}
        sleep(3)
        post '/commands', params: { command: "TTL mykey10"}

        expect(JSON.parse(response.body)).to eq (
          {
            'code' => 0,
            'value' => 1
          }
        )
      end

      it 'a key is timeout' do
        post '/commands', params: { command: "SET mykey10 13" }
        post '/commands', params: { command: "EXPIRE mykey10 5"}
        sleep(8)
        post '/commands', params: { command: "TTL mykey10"}

        expect(JSON.parse(response.body)).to eq (
          {
            'code' => 0,
            'value' => -2
          }
        )
      end
    end

    it 'a key doesn\'t exist' do
      post '/commands', params: { command: "TTL mykey10"}

      expect(JSON.parse(response.body)).to eq (
        {
          'code' => 0,
          'value' => -2
        }
      )
    end

    it 'invalid argument' do
      post '/commands', params: { command: "TTL mykey10 3a"}

      expect(JSON.parse(response.body)).to eq (
        {
          'code' => 2,
          'message' => "ERROR: wrong number of arguments for 'ttl' command"
        }
      )
    end
  end
end
