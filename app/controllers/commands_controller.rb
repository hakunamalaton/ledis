class CommandsController < ApplicationController
  protect_from_forgery with: :null_session
  
  $storage_string = {}
  $storage_key = {}

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
          message: "ERROR: wrong number of arguments for 'set' command"
        }
      elsif new_command.length > 3
        render json: {
          code: 3,
          message: "ERROR: syntax error"
        }
      else
        $storage_string[new_command[1]] = new_command[2]
        render json: {
          code: 0,
          message: "Ok"
        }
      end
    when "GET"
      # check if invalid arguments
      if new_command.length != 2 
        render json: {
          code: 2,
          message: "ERROR: wrong number of arguments for 'get' command"
        }
      else
        render json: {
          code: 0,
          key: new_command[1],
          value: $storage_string[new_command[1]]
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
end
