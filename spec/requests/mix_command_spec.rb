require 'rails_helper'

describe 'Data expiration command API', type: :request do

  it 'SET key value and expiration time for it' do
    post '/commands', params: { command: "SET mykey 50" }
    post '/commands', params: { command: "EXPIRE mykey 5" }
    sleep(6)
    post '/commands', params: { command: "GET mykey" }

    expect(JSON.parse(response.body)).to eq (
      {
        'code' => 0,
        'key' => 'mykey',
        'value' => nil
      }
    )
  end

  it 'SET value for key set and remove some of them' do
    post '/commands', params: { command: "SADD mykey abc 68 1.73" }
    post '/commands', params: { command: "SREM mykey abc cdf" }
    post '/commands', params: { command: "SMEMBERS mykey" }

    expect(JSON.parse(response.body)).to eq (
      {
        'code' => 0,
        'value' => ['68','1.73']
      }
    )
  end

  it 'SET value for key set and remove some of them and set expiration time' do
    post '/commands', params: { command: "SADD mykey abc 68 1.73" }
    post '/commands', params: { command: "SREM mykey abc cdf" }
    post '/commands', params: { command: "EXPIRE mykey 5" }
    sleep(3)
    post '/commands', params: { command: "SMEMBERS mykey" }


    expect(JSON.parse(response.body)).to eq (
      {
        'code' => 0,
        'value' => ['68','1.73']
      }
    )
  end

  it 'SET value for key set and remove some of them but it timeout' do
    post '/commands', params: { command: "SADD mykey abc 68 1.73" }
    post '/commands', params: { command: "SREM mykey abc cdf" }
    post '/commands', params: { command: "EXPIRE mykey 5" }
    sleep(6)
    post '/commands', params: { command: "SMEMBERS mykey" }


    expect(JSON.parse(response.body)).to eq (
      {
        'code' => 0,
        'value' => []
      }
    )
  end

  it 'SET value for key set and remove some of them but it timeout' do
    post '/commands', params: { command: "SADD mykey abc 68 1.73" }
    post '/commands', params: { command: "SET ltt 50" }
    post '/commands', params: { command: "EXPIRE mykey 5" }
    sleep(6)
    post '/commands', params: { command: "KEYS" }


    expect(JSON.parse(response.body)).to eq (
      {
        'code' => 0,
        'keys' => ['ltt']
      }
    )
  end

  it 'SET value for key set timeout something and call sinter' do
    post '/commands', params: { command: "SADD mykey abc 68 1.73" }
    post '/commands', params: { command: "SADD myanotherkey cdf 68 1.80" }
    post '/commands', params: { command: "EXPIRE myanotherkey 5" }
    sleep(3)
    post '/commands', params: { command: "SINTER mykey myanotherkey" }


    expect(JSON.parse(response.body)).to eq (
      {
        'code' => 0,
        'value' => ['68']
      }
    )
  end

  it 'SET value for key set timeout something and call sinter' do
    post '/commands', params: { command: "SADD mykey abc 68 1.73" }
    post '/commands', params: { command: "SADD myanotherkey cdf 68 1.80" }
    post '/commands', params: { command: "EXPIRE myanotherkey 5" }
    sleep(5)
    post '/commands', params: { command: "SINTER mykey myanotherkey" }


    expect(JSON.parse(response.body)).to eq (
      {
        'code' => 0,
        'value' => []
      }
    )
  end

  it 'SET value for key set timeout something and call sinter' do
    post '/commands', params: { command: "SADD mykey abc 68 1.73" }
    post '/commands', params: { command: "SADD myanotherkey cdf 68 1.80" }
    post '/commands', params: { command: "EXPIRE myanotherkey 5" }
    sleep(5)
    post '/commands', params: { command: "SINTER mykey myanotherkey" }


    expect(JSON.parse(response.body)).to eq (
      {
        'code' => 0,
        'value' => []
      }
    )
  end

  it 'SET value for key set timeout something and call sinter' do
    post '/commands', params: { command: "SADD mykey abc 68 1.73" }
    post '/commands', params: { command: "EXPIRE mykey 3" }
    sleep(4)
    post '/commands', params: { command: "DEL mykey" }

    expect(JSON.parse(response.body)).to eq (
      {
        'code' => 0,
        'message' => 0
      }
    )
  end

  it 'SET value for key set then remove it' do
    post '/commands', params: { command: "SADD mykey abc 68 1.73" }
    post '/commands', params: { command: "DEL mykey" }
    post '/commands', params: { command: "TTL mykey" }

    expect(JSON.parse(response.body)).to eq (
      {
        'code' => 0,
        'value' => -2
      }
    )
  end

  it 'SET value for key set then remove it' do
    post '/commands', params: { command: "SADD mykey abc 68 1.73" }
    post '/commands', params: { command: "EXPIRE mykey 50" }
    post '/commands', params: { command: "SET mykey ttt" }
    post '/commands', params: { command: "TTL mykey" }

    expect(JSON.parse(response.body)).to eq (
      {
        'code' => 0,
        'value' => -1
      }
    )
  end

  it 'SET value for key set then remove it' do
    post '/commands', params: { command: "SET mykey abc" }
    post '/commands', params: { command: "EXPIRE mykey 50" }
    post '/commands', params: { command: "SADD mykey ttt" }

    expect(JSON.parse(response.body)).to eq (
      {
        'code' => 4,
        'message' => "ERROR: Operation against a key holding the wrong kind of value"
      }
    )
  end

  it 'SET value for key set then remove it' do
    post '/commands', params: { command: "SET mykey abc" }
    post '/commands', params: { command: "EXPIRE mykey 2" }
    sleep(3)
    post '/commands', params: { command: "SADD mykey ttt" }
    post '/commands', params: { command: "SMEMBERS mykey" }

    expect(JSON.parse(response.body)).to eq (
      {
        'code' => 0,
        'value' => ['ttt']
      }
    )
  end

  it 'SET value for key set then remove it' do
    post '/commands', params: { command: "SET mykey abc" }
    post '/commands', params: { command: "SADD mykey1 ttt" }
    post '/commands', params: { command: "EXPIRE mykey 2" }
    sleep(3)
    post '/commands', params: { command: "SADD mykey ttt" }
    post '/commands', params: { command: "SINTER mykey mykey1" }

    expect(JSON.parse(response.body)).to eq (
      {
        'code' => 0,
        'value' => ['ttt']
      }
    )
  end

  it 'SET value for key set, timeout key, then remove value' do
    post '/commands', params: { command: "SADD mykey1 ttt abc" }
    post '/commands', params: { command: "EXPIRE mykey1 2" }
    sleep(3)
    post '/commands', params: { command: "SREM mykey1 ttt" }

    expect(JSON.parse(response.body)).to eq (
      {
        'code' => 0,
        'message' => 0
      }
    )
  end
end
