require 'rails_helper'

describe 'Back up command API', type: :request do
  describe 'valid SAVE commands' do
    it 'the SAVE command response' do
      post '/commands', params: { command: "SET toan 123" }
      post '/commands', params: { command: "SAVE" }

      expect(JSON.parse(response.body)).to eq(
        {
          'code' => 0,
          'message' => "OK"
        }
      )
    end
  end

  describe 'invalid SAVE commands' do
    it 'invalid arguments passing' do
      post '/commands', params: { command: "SET toan 123" }
      post '/commands', params: { command: "SAVE toan 123" }

      expect(JSON.parse(response.body)).to eq(
        {
          'code' => 2,
          'message' => "ERROR: wrong number of arguments for 'save' command"
        }
      )
    end
  end

  describe 'valid RESTORE commands' do
    it 'the RESTORE command response' do
      post '/commands', params: { command: "SET toan 123" }
      post '/commands', params: { command: "SAVE" }
      post '/commands', params: { command: "RESTORE" }

      expect(JSON.parse(response.body)).to eq(
        {
          'code' => 0,
          'message' => "OK"
        }
      )
    end
  end

  describe 'invalid RESTORE commands' do
    it 'invalid arguments passing' do
      post '/commands', params: { command: "SET toan 123" }
      post '/commands', params: { command: "SAVE" }
      post '/commands', params: { command: "RESTORE toan 123" }

      expect(JSON.parse(response.body)).to eq(
        {
          'code' => 2,
          'message' => "ERROR: wrong number of arguments for 'restore' command"
        }
      )
    end
  end
end

