require 'set'

class CommandsController < ApplicationController
  protect_from_forgery with: :null_session
  
  $storage_string = {}
  $storage_set = {}
  $expire_key = {}

  def index
  end

  def create
    new_command = commands_params.split(" ")

    #  check error before logical code
    case new_command[0].upcase
    when "SET" 
      if new_command.length < 3 
        render json: {
          code: 2,
          message: error_code_2('set')
        }
      elsif new_command.length > 3
        render json: {
          code: 3,
          message: "ERROR: syntax error"
        }
      else
        $storage_string[new_command[1]] = new_command[2]
        $storage_set.delete(new_command[1]) if $storage_set.has_key?(new_command[1])
        $expire_key.delete(new_command[1]) if $expire_key.has_key?(new_command[1])
        render json: {
          code: 0,
          message: "OK"
        }
      end
    when "GET"
      # check if invalid arguments
      if new_command.length != 2 
        render json: {
          code: 2,
          message: error_code_2('get')
        }
      else
        key = new_command[1]
        if ($expire_key[key] == nil) or ($expire_key[key] and key_expiration_time($expire_key[key]))
          render json: {
            code: 0,
            key: key,
            value: $storage_string[new_command[1]]
          }
        else
          $storage_string.delete(key) if $storage_string.has_key?(key)
          render json: {
            code: 0,
            key: key,
            value: nil
          }
        end
      end
    when "SADD"
      if new_command.length <= 2
        render json: {
          code: 2,
          message: error_code_2('sadd')
        }
      else
        if $storage_string.has_key?(new_command[1])
          if check_key_valid?(new_command[1],'string')
            render json: {
              code: 4,
              message: "ERROR: Operation against a key holding the wrong kind of value"
            }
          end
        end
        if !$storage_string.has_key?(new_command[1]) or ($storage_string.has_key?(new_command[1]) and !check_key_valid?(new_command[1],'string'))
          key = new_command[1]
          $expire_key.delete(key) if $expire_key.has_key?(key)
          new_quantity_value = 0
          if $storage_set[key]
            new_quantity_value = (new_command[2..].to_set - $storage_set[key]).length()
            $storage_set[key].add(new_command[2..].to_set)
          else
            new_quantity_value = (new_command[2..].to_set).length()
            $storage_set[key] = new_command[2..].to_set
          end
          render json: {
            code: 0,
            message: new_quantity_value
          }
        end
        # binding.irb
      end
    when "SREM"
      if new_command.length <= 2
        render json: {
          code: 2,
          message: error_code_2('srem')
        }
      else
        quantity_del_value = 0
        key = new_command[1]
        if $storage_set[key] and check_key_valid?(key,'set')
          quantity_del_value = (new_command[2..].to_set & $storage_set[key]).length()
          $storage_set[key] -= new_command[2..].to_set
        end
        render json: {
          code: 0,
          message: quantity_del_value
        }
      end
    when "SMEMBERS"
      if new_command.length == 2
        key = new_command[1]
        # binding.irb
        if ($expire_key[key] == nil) or (($expire_key[key] != -2) and key_expiration_time($expire_key[key]))
          render json: {
            code: 0,
            value: $storage_set[key]
          }
        else
          $storage_set.delete(key) if $storage_set.has_key?(key)
          render json: {
            code: 0,
            value: []
          }
        end
      else
        render json: {
          code: 2,
          message: error_code_2('smembers')
        }
      end
    when "SINTER"
      if new_command.length <= 1
        render json: {
          code: 2,
          message: error_code_2('sinter')
        }
      elsif new_command.length == 2
        # binding.irb
        render json: {
          code: 0,
          value: $storage_set[new_command[1]]
        }
      else
        # binding.irb
        value = []

        new_command[1..].each do |key| 
          check_key_valid?(key,'set')
        end

        new_command[1..].each do |key| 
          if $storage_set[key]
            value.push($storage_set[key])
          else
            value.push([])
          end
        end
        value = value.inject(:&)
        # binding.irb
        render json: {
          code: 0,
          value: value
        }
      end
    when "KEYS"
      if new_command.length >= 2
        render json: {
          code: 2,
          message: error_code_2('keys')
        }
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
        render json: {
          code: 0,
          keys: all_keys
        }
      end
    when "DEL"
      if new_command.length <=1 or new_command.length >= 3
        render json: {
          code: 2,
          message: error_code_2('del')
        }
      else
        quantity_deleted = 0
        if $storage_string.has_key?(new_command[1])
          if check_key_valid?(new_command[1],'string')
            $storage_string.delete(new_command[1])
            quantity_deleted = 1
          end
        elsif $storage_set.has_key?(new_command[1])
          if check_key_valid?(new_command[1],'set')
            $storage_set.delete(new_command[1])
            quantity_deleted = 1
          end
        end
        render json: {
          code: 0,
          message: quantity_deleted
        }
      end
    when "EXPIRE"
      if new_command.length > 3 or new_command.length <= 2
        render json: {
          code: 2,
          message: error_code_2('expire')
        }
      else
        key = new_command[1]
        second = new_command[2]
        side = 1
        if second[0] == '-'
          side = -1
          second = second[1..]
        end
        
        if second.match?(/[^0-9]/)
          render json: {
            code: 5,
            message: "ERROR: value is not an integer or out of range"
          }
          return
        else
          second = second.to_i * side
        end

        if $storage_string.has_key?(key) or $storage_set.has_key?(key)
          # that key is exist and has default ttl
          
          if second <=0 
            $expire_key[key] = -2
            $storage_string.delete(key) if $storage_string.has_key?(key)
            $storage_set.delete(key) if $storage_set.has_key?(key)
          else
            # binding.irb
            if ($expire_key[key] == nil) or ($expire_key[key] != -2 and Time.now - $expire_key[key] <= 0) 
              $expire_key[key] = Time.now + second
            else
              render json: {
                code: 0,
                value: 0
              }
              return
            end
          end
          render json: {
            code: 0,
            value: 1
          }
        else
          render json: {
            code: 0,
            value: 0
          }
        end
      end
    when "TTL"
      if new_command.length != 2
        render json: {
          code: 2,
          message: error_code_2('ttl')
        }
      else
        key = new_command[1]
        if !$storage_set.has_key?(key) and !$storage_string.has_key?(key) 
          render json: {
            code: 0,
            value: -2
          }
        elsif $expire_key[key]
          time_remain = ($expire_key[key] - Time.now)
          if key_expiration_time($expire_key[key])
            render json: {
              code: 0,
              value: time_remain.to_i
            }
          else
            $expire_key[key] = -2
            $storage_string.delete(key) if $storage_string.has_key?(key)
            $storage_set.delete(key) if $storage_set.has_key?(key)
            render json: {
              code: 0,
              value: -2
            }
          end
        else
          render json: {
            code: 0,
            value: -1
          }
        end
        
      end
    else
      render json: {
        code: 1,
        message: "Error: unknown command '#{new_command[0]}'"
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
    (time_to_be_expired - Time.now) > 0
  end

  def check_key_valid?(key, sequence)
    if sequence == 'string'
      if $expire_key[key] == nil or key_expiration_time($expire_key[key]) 
        return true
      else
        $storage_string.delete(key) if $storage_string.has_key?(key)
        return false
      end
    else
      if $expire_key[key] == nil or key_expiration_time($expire_key[key]) 
        return true
      else
        $storage_set.delete(key) if $storage_set.has_key?(key)
        return false
      end
    end
  end
end
