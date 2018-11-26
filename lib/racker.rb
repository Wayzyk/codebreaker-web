require_relative './controller'

class Racker
  attr_reader :game_do, :request

  def self.call(env)
    new(env).response.finish
  end

  def initialize(env)
    @request = Rack::Request.new(env)
    @game_do = Controller.new(@request)
  end

  def response
    case request.path
    when '/' then game_do.index
    when '/check_input' then game_do.check
    when '/show_hint' then game_do.show_hint
    when '/new_game' then game_do.new_game
    when '/save_result' then game_do.save_result
    else game_do.not_found
    end
  end

end