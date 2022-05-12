class CommandsController < ApplicationController
  protect_from_forgery with: :null_session
  
  $storage = {}

  def index
  end

  def create
    new_command = commands_params.split(" ")

    #  check error before logical code
    case new_command[0].upcase
    when "SET" 
      $storage[new_command[1]] = new_command[2]
      render json: {
        code: 0,
        message: "Ok"
      }
    when "GET"
      # check if null
      render json: {
        code: 0,
        key: new_command[1],
        value: $storage[new_command[1]]
      }
    else
      render json: {
        code: 1,
        message: "Error"
      }
    end

    # p $storage
  end

  private 
  def commands_params
    params.require(:command)
  end
end
