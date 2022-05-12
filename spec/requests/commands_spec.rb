require 'rails_helper'

describe 'String command API', type: :request do
  describe 'set value string key' do
    it 'set value for a string key' do
      post '/commands', params: { command: "SET abc 123" }

      expect(JSON.parse(response.body)).to eq (
        {
          'code' => 0,
          'message' => 'Ok'
        }
      )
    end

    it 'set multiple values for a string key' do
      post '/commands', params: { command: "SET abc 123" }
      post '/commands', params: { command: "SET abc 456" }
      
      expect(JSON.parse(response.body)).to eq (
        {
          'code' => 0,
          'message' => 'Ok'
        }
      )
    end

    it 'set multiple values for multiples string keys' do
      post '/commands', params: { command: "SET abc 123" }
      post '/commands', params: { command: "SET mnq 456" }
        
      expect(JSON.parse(response.body)).to eq (
        {
          'code' => 0,
          'message' => 'Ok'
        }
      )
    end
  end

  describe 'get value string key' do
    before do
      post '/commands', params: { command: "SET abc 123" }
      post '/commands', params: { command: "SET xyz 456" }
      post '/commands', params: { command: "SET ltt 789" }
      post '/commands', params: { command: "SET xyz 111" }
      
    end

    it 'get a value if a key distinct' do
      post '/commands', params: { command: "GET abc" }

      expect(JSON.parse(response.body)).to eq (
        {
          'code' => 0,
          'key' => 'abc',
          'value' => '123'
        }
      )
    end

    it 'get a value if a key doesn\'t distinct' do
      post '/commands', params: { command: "GET mnp" }

      expect(JSON.parse(response.body)).to eq (
        {
          'code' => 0,
          'key' => 'mnp',
          'value' => nil
        }
      )
    end

    it 'get a value if a key distinct' do
      post '/commands', params: { command: "GET ltt" }
  
      expect(JSON.parse(response.body)).to eq (
        {
          'code' => 0,
          'key' => 'ltt',
          'value' => '789'
        }
      )
    end

    it 'override then get value of key' do
      post '/commands', params: { command: "GET xyz" }
      
      expect(JSON.parse(response.body)).to eq (
        {
          'code' => 0,
          'key' => 'xyz',
          'value' => '111'
        }
      )
    end
  end

  describe 'Invalid syntax' do 
    it 'invalid syntax' do
      post '/commands', params: {command: "MET abc 123"}

      expect(JSON.parse(response.body)).to eq (
        {
          'code' => 1,
          'message' => 'Error: unknown command \'MET\''
        }
      )
    end
  end

  describe 'invalid argument' do 
    it 'invalid argument in get command' do
      post '/commands', params: { command: "GET toan 1" }

      expect(JSON.parse(response.body)).to eq (
        {
          'code' => 2,
          'message' => "ERROR: wrong number of arguments for 'get' command"
        }
      )
    end

    it 'invalid argument in set command' do
      post '/commands', params: { command: "SET toan 123 m" }
    
      expect(JSON.parse(response.body)).to eq (
        {
          'code' => 3,
          'message' => "ERROR: syntax error"
        }
      )
    end

    it 'invalid argument in set command' do
      post '/commands', params: { command: "SET toan" }
  
      expect(JSON.parse(response.body)).to eq (
        {
          'code' => 2,
          'message' => "ERROR: wrong number of arguments for 'set' command"
        }
      )
    end
  end
end