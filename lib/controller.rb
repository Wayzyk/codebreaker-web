require 'erb'
require 'yaml'
require_relative './helper'

class Controller
  include Helper
  attr_accessor :game, :sid, :sessions, :request
  attr_reader :agree_to_save
  DATABASE = 'sessions_data.yaml'

  def initialize(req)
    @request = req
    @request.session['init'] = true
    @sid = @request.session['session_id']
    @sessions = load_sessions_data
    @game = sessions[sid]
    @agree_to_save ||= false
    guesses
    results
  end

  def index
    @game ||= Codebreaker::Game.new
    save_game
    Rack::Response.new(render('index.html.erb'))
  end

  def check
    res = game.check_input(request.params['guess'])
    save_game
    unless request.params['guess'] == ''
      res.empty? ? @results.push('mishit') : @results.push(res)
      @guesses.push(request.params['guess'])
      Rack::Response.new do |response|
          response.set_cookie('guesses', @guesses)
          response.set_cookie('results', @results)
          response.redirect('/')
      end
    else
      Rack::Response.new do |response|
        response.redirect('/')
      end
    end
  end

  def show_hint
    unless game.hint
      Rack::Response.new do |response|
        response.redirect('/')
      end
    else
      h = game.hint_answer
      save_game
      Rack::Response.new do |response|
        response.set_cookie('hint', h)
        response.redirect('/')
      end
    end
  end

  def new_game
    @game = Codebreaker::Game.new
    save_game
    Rack::Response.new do |response|
        response.set_cookie('guesses', [])
        response.set_cookie('results', [])
        response.set_cookie('hint', nil)
        response.redirect('/')
    end
  end

  def save_result
    name = @request.params['name']
    File.open('score.yml', 'a') { |f| f.write(YAML.dump("#{name}; #{Codebreaker::Game::ATTEMPT_NUMBER - game.available_attempts}; #{Time.now.strftime('%d-%m-%Y %R')};")) }
    @agree_to_save = true
    Rack::Response.new do |response|
      response.redirect('/')
    end
  end

  def load_score
    saved_score = []
    if File.exist?('score.yml')
      file = File.open('score.yml')
      score = YAML::load_documents(file) do |doc|
        saved_score.push  doc.split(';')
      end
    end
    saved_score
  end

  def not_found
    Rack::Response.new('Not Found', 404)
  end

  private

  def guesses
    @guesses = @request.cookies['guesses'] || []
    @guesses = @guesses.split('&') unless @guesses.is_a? Array
  end

  def results
    @results = @request.cookies['results'] || []
    @results = @results.split('&') unless @results.is_a? Array
  end

  def load_sessions_data
    File.exist?(DATABASE) ? YAML.load_file(DATABASE) : {}
  end

  def save_game
    sessions[sid] = game
    File.open(DATABASE, 'w') { |f| f.write sessions.to_yaml }
  end

  def render(template)
    path = File.expand_path("../views/#{template}", __FILE__)
    ERB.new(File.read(path)).result(binding)
  end
end