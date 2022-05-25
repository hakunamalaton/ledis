require 'set'
require 'time'

class CommandsController < ApplicationController
  protect_from_forgery with: :null_session

  CODE_SUCCESS = 0
  CODE_WRONG_SYNTAX = 1
  CODE_WRONG_ARGS = 2
  CODE_ERROR_SYNTAX = 3
  CODE_INVALID_TYPE = 4
  CODE_OUT_OF_RANGE = 5

  OK_MESSAGE = "OK"
  SYNTAX_ERROR_MESSAGE = "ERROR: syntax error"
  INVALID_TYPE_MESSAGE = "ERROR: Operation against a key holding the wrong kind of value"
  OUT_OF_RANGE_MESSAGE = "ERROR: value is not an integer or out of range"

  def index
  end

  def create
    segments = commands_params.squeeze(" ").split(" ")
    code = CODE_SUCCESS
    message = OK_MESSAGE
    #  check error before logical code
    
    case segments[0].upcase
    when "SET" 
      if segments.length < 3 
        code = CODE_WRONG_ARGS
        message = error_code_2('set')
      elsif segments.length > 3
        code = CODE_ERROR_SYNTAX
        message = SYNTAX_ERROR_MESSAGE
      else
        $storage_string[segments[1]] = segments[2]
        $storage_set.delete(segments[1]) if $storage_set.has_key?(segments[1])
        $expire_key.delete(segments[1]) if $expire_key.has_key?(segments[1])
      end
      render json: {
        code: code,
        message: message
      }
    when "GET"
      key = nil
      value = nil
      # check if invalid arguments
      if segments.length != 2 
        code = CODE_WRONG_ARGS
        message = error_code_2('get')
        # key = nil
      else
        key = segments[1]
        if ($expire_key[key] == nil) || ($expire_key[key] && key_expiration_time($expire_key[key]))
          code = CODE_SUCCESS
          value = $storage_string[key]
        else
          $storage_string.delete(key) if $storage_string.has_key?(key)
          code = CODE_SUCCESS
          key = key
          value = nil
        end
      end
      get_response = {
        code: code
      }

      if code != 0
        get_response["message".to_sym] = message 
      else
        get_response["key".to_sym] = key
        get_response["value".to_sym] = value          
      end
      render json: get_response
    when "SADD"
      if segments.length <= 2
        code = CODE_WRONG_ARGS
        message = error_code_2('sadd')
      else
        if $storage_string.has_key?(segments[1])
          if check_key_valid?(segments[1],'string')
            code = CODE_INVALID_TYPE
            message = INVALID_TYPE_MESSAGE
          end
        end
        if !$storage_string.has_key?(segments[1]) || ($storage_string.has_key?(segments[1]) && !check_key_valid?(segments[1],'string'))
          key = segments[1]
          $expire_key.delete(key) if $expire_key.has_key?(key)
          new_quantity_value = 0
          if $storage_set[key]
            new_quantity_value = (segments[2..].to_set - $storage_set[key]).length()
            $storage_set[key].merge(segments[2..].to_set)
          else
            new_quantity_value = (segments[2..].to_set).length()
            $storage_set[key] = segments[2..].to_set
          end
          code = CODE_SUCCESS
          message = new_quantity_value
        end
      end
      render json: {
        code: code,
        message: message
      }
    when "SREM"
      if segments.length <= 2
        code = CODE_WRONG_ARGS
        message = error_code_2('srem')
      else
        quantity_del_value = 0
        key = segments[1]
        if $storage_set[key] && check_key_valid?(key,'set')
          quantity_del_value = (segments[2..].to_set & $storage_set[key]).length()
          $storage_set[key] -= segments[2..].to_set
          $storage_set.delete(key) if $storage_set[key].empty?
        end
        message = quantity_del_value
      end
      render json: {
        code: code,
        message: message
      }
    when "SMEMBERS"
      value = nil
      if segments.length == 2
        key = segments[1]
        if ($expire_key[key] == nil) || (($expire_key[key] != -2) && key_expiration_time($expire_key[key]))
          code = CODE_SUCCESS
          value = $storage_set[key] ? $storage_set[key] : []
        else
          $storage_set.delete(key) if $storage_set.has_key?(key)
          code = CODE_SUCCESS
          value = []
        end
      else
        code = CODE_WRONG_ARGS
        message = error_code_2('smembers')
      end
      smembers_response = {
        code: code
      }
      if code != 0
        # error case
        smembers_response["message".to_sym] = message
      else
        smembers_response["value".to_sym] = value
      end
      render json: smembers_response
    when "SINTER"
      value = nil
      if segments.length <= 1
        code = CODE_WRONG_ARGS
        message = error_code_2('sinter')
      elsif segments.length == 2
        value = $storage_set[segments[1]]
      else
        value = []
        segments[1..].each do |key| 
          check_key_valid?(key,'set')
        end

        segments[1..].each do |key| 
          if $storage_set[key]
            value.push($storage_set[key])
          else
            value.push([])
          end
        end
        value = value.inject(:&)
      end
      sinter_response = {
        code: code
      }
      if code != 0
        # error case
        sinter_response["message".to_sym] = message
      else
        sinter_response["value".to_sym] = value
      end
      render json: sinter_response
    when "KEYS"
      keys = nil
      if segments.length >= 2
        code = CODE_WRONG_ARGS
        message = error_code_2('keys')
      else
        all_keys = []
        $storage_string.keys.each do |key|
          check_key_valid?(key,'string')
        end
        $storage_set.keys.each do |key|
          check_key_valid?(key,'set')
        end
        all_keys += $storage_string.keys 
        all_keys += $storage_set.keys 
        keys = all_keys
      end
      keys_response = {
        code: code
      }
      if code != 0
        keys_response["message".to_sym] = message
      else
        keys_response["keys".to_sym] = keys
      end
      render json: keys_response
    when "DEL"
      if segments.length <=1 || segments.length >= 3
        code = CODE_WRONG_ARGS
        message = error_code_2('del')
      else
        quantity_deleted = 0
        if $storage_string.has_key?(segments[1])
          if check_key_valid?(segments[1],'string')
            $storage_string.delete(segments[1])
            quantity_deleted = 1
          end
        elsif $storage_set.has_key?(segments[1])
          if check_key_valid?(segments[1],'set')
            $storage_set.delete(segments[1])
            quantity_deleted = 1
          end
        end
        message = quantity_deleted
      end
      render json: {
        code: code,
        message: message
      }
    when "EXPIRE"
      
      value = nil
      if segments.length > 3 || segments.length <= 2
        code = CODE_WRONG_ARGS
        message = error_code_2('expire')
      else
        key = segments[1]
        second = segments[2]
        side = 1
        if second[0] == '-'
          side = -1
          second = second[1..]
        end
        
        if second.match?(/[^0-9]/)
          code = CODE_OUT_OF_RANGE
          message = OUT_OF_RANGE_MESSAGE
        else
          second = second.to_i * side
        end

        if $storage_string.has_key?(key) || $storage_set.has_key?(key)
          # that key is exist && has default ttl
          if second <= 0 
            $expire_key[key] = -2
            $storage_string.delete(key) if $storage_string.has_key?(key)
            $storage_set.delete(key) if $storage_set.has_key?(key)
          else
            if ($expire_key[key] == nil) || ($expire_key[key] != -2 && Time.now - $expire_key[key] <= 0) 
              $expire_key[key] = Time.now + second
            else
              value = 0
            end
          end
          value = 1 if value != 0
        else
          value = 0
        end
      end
      expire_response = {
        code: code
      }
      if code != 0
        expire_response["message".to_sym] = message
      else
        expire_response["value".to_sym] = value
      end
      render json: expire_response
    when "TTL"
      value = nil
      if segments.length != 2
        code = CODE_WRONG_ARGS
        message = error_code_2('ttl')
      else
        key = segments[1]
        if !$storage_set.has_key?(key) && !$storage_string.has_key?(key) 
          value = -2
        elsif $expire_key[key]
          time_remain = ($expire_key[key] - Time.now)
          if key_expiration_time($expire_key[key])
            value = time_remain.to_i > 0 ? time_remain.to_i : -2
          else
            $expire_key[key] = -2
            $storage_string.delete(key) if $storage_string.has_key?(key)
            $storage_set.delete(key) if $storage_set.has_key?(key)
            value = -2
          end
        else
          value = -1
        end
      end
      ttl_response = {
        code: code
      }
      if code != 0
        ttl_response["message".to_sym] = message
      else
        ttl_response["value".to_sym] = value
      end
      render json: ttl_response
    when "SAVE"
      if segments.length > 1
        code = 2
        message = error_code_2('save')
      end
      if code == 0
        expire_key_saving = {}
        $expire_key.each { |key, expire|
          expire_key_saving[key] = expire.to_s
        }
        storage_set_to_array = {}
        $storage_set.each { |key, set|
          storage_set_to_array[key] = set.to_a
        }
        file = File.open("app/assets/backup/dump.txt", "w") { |f|
          f.write "$storage_string = #{$storage_string}\n$storage_set = #{storage_set_to_array}\n$expire_key = #{expire_key_saving}"
        }
      end
      
      render json: {
        code: code,
        message: message
      }
      
    when "RESTORE"
      if segments.length > 1
        code = 2
        message = error_code_2('restore')
      end
      if code == 0
        file = File.open("app/assets/backup/dump.txt")
        last_data = file.read.split("\n")
        # find the index
        # index_string_hash = last_data[0].index('=')+2
        # # assign to string hash
        # $storage_string = JSON.parse(last_data[0][index_string_hash..].gsub("=>",":"))

        # # find the index
        # index_set_hash = last_data[1].index('=')+2
        # # assign to string hash
        # $storage_set = JSON.parse(last_data[1][index_set_hash..].gsub("=>",":"))

        # # find the index
        # index_expire_hash = last_data[2].index('=')+2
        # # assign to string hash
        # $expire_key = JSON.parse(last_data[2][index_expire_hash..].gsub("=>",":"))

        # not secure
        eval(last_data[0])
        eval(last_data[1])
        eval(last_data[2])

        # puts $expire_key
        unless $expire_key.empty? 
          $expire_key.each do |key, expire_string|
            $expire_key[key] = Time.parse(expire_string) unless expire_string == "-2"
          end
        end
        # change format of $storage_set 
        unless $storage_set.empty? 
          $storage_set.each do |key, set_array|
            $storage_set[key] = set_array.to_set
          end
        end

        file.close
      end

      render json: {
        code: code,
        message: message
      }
    else # unknown command or undefined command
      render json: {
        code: CODE_WRONG_SYNTAX,
        message: "Error: unknown command '#{segments[0]}'"
      }
    end

  end

  private 
  def commands_params
    params.require(:command)
  end

  def error_code_2(command)
    "ERROR: wrong number of arguments for '#{command}' command"
  end

  def key_expiration_time(time_to_be_expired)
    return false if time_to_be_expired == -2
    (time_to_be_expired - Time.now) > 0
  end

  def check_key_valid?(key, sequence)
    if sequence == 'string'
      if $expire_key[key] == nil || key_expiration_time($expire_key[key]) 
        return true
      else
        $storage_string.delete(key) if $storage_string.has_key?(key)
        return false
      end
    else
      if $expire_key[key] == nil || key_expiration_time($expire_key[key]) 
        return true
      else
        $storage_set.delete(key) if $storage_set.has_key?(key)
        return false
      end
    end
  end

end
