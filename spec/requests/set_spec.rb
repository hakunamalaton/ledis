require 'rails_helper'
require 'set'

describe 'Set command API', type: :request do
  describe 'sadd values' do
    it 'add a value for a set key' do
      post '/commands', params: { command: "SADD abc 123" }

      expect(JSON.parse(response.body)).to eq (
        {
          'code' => 0,
          'message' => 1
        }
      )
    end

    it 'add multiple distinct value for a set key' do
      post '/commands', params: { command: "SADD mnp 123 456 789" }

      expect(JSON.parse(response.body)).to eq (
        {
          'code' => 0,
          'message' => 3
        }
      )
    end

    it 'add multiple but not distinct value for a set key' do
      post '/commands', params: { command: "SADD xyz 123 456 123 456" }
  
      expect(JSON.parse(response.body)).to eq (
        {
          'code' => 0,
          'message' => 2
        }
      )
    end

    it 'add value to an exist key set' do
      post '/commands', params: { command: "SADD ltt 123 456 123 456" }
      post '/commands', params: { command: "SADD ltt 567 456" }
      
      expect(JSON.parse(response.body)).to eq (
        {
          'code' => 0,
          'message' => 1
        }
      )
    end
    # ADD from a SET key, ADD key invalid arguments
    describe 'ERROR on sadd commands' do
      it 'sadd after set command' do
        post '/commands', params: { command: "SET abc 123" }
        post '/commands', params: { command: "SADD abc 1" }

        expect(JSON.parse(response.body)).to eq (
          {
            'code' => 4,
            'message' => "ERROR: Operation against a key holding the wrong kind of value"
          }
        )
      end

      it 'sadd after set command' do
        post '/commands', params: { command: "SADD abc" }
  
        expect(JSON.parse(response.body)).to eq (
          {
            'code' => 2,
            'message' => "ERROR: wrong number of arguments for 'sadd' command"
          }
        )
      end
    end
  end
  
  describe 'SREM values' do
    describe 'Valid SREM commands' do

      before do
        post '/commands', params: {command: "SADD ljc 123 mnp ljc 456"}
        post '/commands', params: {command: "SADD ljcc 123 mnp ljc 456"}

      end

      it 'SREM some values of exist key' do
        post '/commands', params: {command: "SREM ljc 123 456"}
    
        expect(JSON.parse(response.body)).to eq (
          {
            'code' => 0,
            'message' => 2    
          }
        )
      end
    
      it 'SREM some unexist and exist values of exist key' do
        post '/commands', params: {command: "SREM ljcc 123 456 abc"}
    
        expect(JSON.parse(response.body)).to eq (
          {
            'code' => 0,
            'message' => 2    
          }
        )
      end
    
      it 'SREM all unexist values of exist key' do
        post '/commands', params: {command: "SREM ljc abc xyz"}
        
        expect(JSON.parse(response.body)).to eq (
          {
            'code' => 0,
            'message' => 0    
          }
        )
      end
    
      it 'SREM values of unexist key' do
        post '/commands', params: {command: "SREM ltt abc xyz"}
        
        expect(JSON.parse(response.body)).to eq (
          {
            'code' => 0,
            'message' => 0    
          }
        )
      end
    end
    # Add srem invalid argument
    describe 'ERROR on SREM commands' do
      it 'SREM invalid arguments errors' do
        post '/commands', params: {command: "SREM ltt"}
        
        expect(JSON.parse(response.body)).to eq (
          {
            'code' => 2,
            'message' => "ERROR: wrong number of arguments for 'srem' command"   
          }
        )
      end
    end
  end

  describe 'SMEMBERS' do
    describe 'SMEMBERS on valid key' do
      it 'access to exist key set' do 
        post '/commands', params: { command: "SADD tlt 123 456" }
        post '/commands', params: { command: "SMEMBERS tlt" }

        expect(JSON.parse(response.body)).to eq (
          {
            'code' => 0,
            'value' => ['123', '456']
          }
        )
      end

      it 'access to exist key that add duplicate value twice' do 
        post '/commands', params: { command: "SADD tlt 123 456" }
        post '/commands', params: { command: "SADD tlt 123 456" }
        post '/commands', params: { command: "SMEMBERS tlt" }

        expect(JSON.parse(response.body)).to eq (
          {
            'code' => 0,
            'value' => ['123', '456']
          }
        )
      end

      it 'access to unexist key set' do
        post '/commands', params: { command: "SMEMBERS yut" }

        expect(JSON.parse(response.body)).to eq (
          {
            'code' => 0,
            'value' => []
          }
        )
      end
    end

    describe 'SMEMBERS on invalid key' do
      it 'arguments passing is 2' do 
        post '/commands', params: { command: "SMEMBERS tlt ttl" }

        expect(JSON.parse(response.body)).to eq (
          {
            'code' => 2,
            'message' => "ERROR: wrong number of arguments for 'smembers' command"
          }
        )
      end

      it 'no key set is given' do
        post '/commands', params: { command: "SMEMBERS" }

        expect(JSON.parse(response.body)).to eq (
          {
            'code' => 2,
            'message' => "ERROR: wrong number of arguments for 'smembers' command"
          }
        )
      end
    end
  end

  describe 'SINTER' do 
    describe 'SINTER on valid key' do
      it '2 set key inter' do
        post '/commands', params: { command: "SADD ltt 1 2 3 a b c" }
        post '/commands', params: { command: "SADD ttl 1 4 7 c d e" }
        post '/commands', params: { command: "SADD ttt c" }
        post '/commands', params: { command: "SADD tlt something has no same" }
        post '/commands', params: { command: "SINTER ltt ttl" }

        expect(JSON.parse(response.body)).to eq (
          {
            'code' => 0,
            'value' => ['1', 'c']
          }
        )
      end

      it '3 set key inter, result is not empty' do
        post '/commands', params: { command: "SINTER ltt ttl ttt" }

        expect(JSON.parse(response.body)).to eq (
          {
            'code' => 0,
            'value' => ['c']
          }
        )
      end

      it '3 set key inter, result is empty' do
        post '/commands', params: { command: "SINTER ltt ttl tlt" }

        expect(JSON.parse(response.body)).to eq (
          {
            'code' => 0,
            'value' => []
          }
        )
      end

      it '1 set key inter' do
        post '/commands', params: { command: "SINTER ltt" }

        expect(JSON.parse(response.body)).to eq (
          {
            'code' => 0,
            'value' => ['1','2','3','a','b','c']
          }
        )
      end

      it '1 set key inter but not exist' do
        post '/commands', params: { command: "SINTER mmm" }

        expect(JSON.parse(response.body)).to eq (
          {
            'code' => 0,
            'value' => nil
          }
        )
      end
    end

  end
end
