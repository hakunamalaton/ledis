require 'set'

class CommandsController < ApplicationController
  protect_from_forgery with: :null_session
  
  $storage_string = {}
  $storage_set = {}
  

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
        render json: {
          code: 0,
          key: new_command[1],
          value: $storage_string[new_command[1]]
        }
      end
    when "SADD"
      if new_command.length <= 2
        render json: {
          code: 2,
          message: error_code_2('sadd')
        }
      else
        if $storage_string.has_key?(new_command[1])
          render json: {
            'code' => 4,
            'message' => "ERROR: Operation against a key holding the wrong kind of value"
          }
        else
          new_quantity_value = 0
          if $storage_set[new_command[1]]
            new_quantity_value = (new_command[2..].to_set - $storage_set[new_command[1]]).length()
            $storage_set[new_command[1]].add(new_command[2..].to_set)
          else
            new_quantity_value = (new_command[2..].to_set).length()
            $storage_set[new_command[1]] = new_command[2..].to_set
          end
          render json: {
            code: 0,
            message: new_quantity_value
          }
        end
      end
    when "SREM"
      if new_command.length <= 2
        render json: {
          code: 2,
          message: error_code_2('srem')
        }
      else
        quantity_del_value = 0
        if $storage_set[new_command[1]]
          quantity_del_value = (new_command[2..].to_set & $storage_set[new_command[1]]).length()
          $storage_set[new_command[1]] -= new_command[2..].to_set
        end
        render json: {
          code: 0,
          message: quantity_del_value
        }
      end
    when "SMEMBERS"
      # Yet write test cases for it
      if new_command.length == 2
        render json: {
          code: 0,
          value: $storage_set[new_command[1]]
        }
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
          value.push($storage_set[key])  
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
          $storage_string.delete(new_command[1])
          quantity_deleted = 1
        elsif $storage_set.has_key?(new_command[1])
          $storage_set.delete(new_command[1])
          quantity_deleted = 1
        end
        render json: {
          code: 0,
          message: quantity_deleted
        }
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
end
