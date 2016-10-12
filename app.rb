require 'sinatra'
require 'sinatra/contrib'
require "sinatra/reloader" if development?
require 'sinatra/flash'
require 'active_record'
require 'hamlit'
require 'dotenv'
require 'omniauth-twitter'
require 'twitter'
require 'irkit'

ActiveRecord::Base.establish_connection(ENV['DATABASE_URL'] || 'sqlite3:db/development.db')

configure do
  Dotenv.load

  enable :sessions
  set :session_secret, ENV['SESSION_SECRET']

  set :haml, format: :html5

  use OmniAuth::Builder do
    provider :twitter, ENV['TWITTER_CONSUMER_KEY'], ENV['TWITTER_CONSUMER_SECRET']
  end
end

helpers do
  def logged_in?
    session[:twitter_oauth]
  end

  def paid?
    paid_brothers = []
    Brother.order("id desc").all.each do |brother|
      paid_brothers.push(brother.screen_name)
    end
    paid_brothers.include?(session[:screen_name])
  end

  def shikakun?
    session[:screen_name] === 'shikakun'
  end

  def current_status
    Activity.last.status
  end

  def japanese_status(status)
    case status
    when 'hikari'
      '点けました'
    when 'yami'
      '消しました'
    end
  end

  def twitter
    Twitter::REST::Client.new do |config|
      config.consumer_key        = ENV['TWITTER_CONSUMER_KEY']
      config.consumer_secret     = ENV['TWITTER_CONSUMER_SECRET']
      config.access_token        = ENV['TWITTER_SHIKAKUN_TOKEN']
      config.access_token_secret = ENV['TWITTER_SHIKAKUN_TOKEN_SECRET']
    end
  end
end

class Activity < ActiveRecord::Base
end

class Brother < ActiveRecord::Base
end

get '/' do
  @activities = Activity.order("id desc").all
  haml :index
end

get '/hikari', '/yami' do
  unless logged_in?
    session[:redirect] = request.url
    redirect '/join'
  end

  unless paid?
    redirect '/kanekure'
  end

  param = request.path_info

  if param === '/hikari'
    irdata = IRKit::App::Data['IR']['lighting_on']
    message = "@#{session[:screen_name]} が鹿の自宅の照明を点けました"
    Activity.create({screen_name: session[:screen_name], status: 'hikari'})
  elsif param === '/yami'
    irdata = IRKit::App::Data['IR']['lighting_off']
    message = "@#{session[:screen_name]} が鹿の自宅の照明を消しました"
    Activity.create({screen_name: session[:screen_name], status: 'yami'})
  else
    redirect '/'
  end

  flash[:message] = message

  if ENV['RACK_ENV'] === 'development'
    redirect '/'
  end

  irkit = IRKit::InternetAPI.new(clientkey: ENV['IRKIT_CLIENTKEY'], deviceid: ENV['IRKIT_DEVICEID'])
  res = irkit.post_messages(irdata)
  case res.code
  when 200
    redirect '/'
  else
    raise res
  end
end

get '/kanekure' do
  redirect '/' unless logged_in?
  redirect '/' if paid?

  haml :kanekure
end

get '/join' do
  redirect '/auth/twitter'
end

get '/exit' do
  session.clear
  redirect '/'
end

get '/auth/twitter/callback' do
  session[:twitter_oauth] = env['omniauth.auth'][:credentials]
  session[:screen_name] = env['omniauth.auth'][:info][:nickname]

  if session[:redirect]
    redirect session[:redirect]
  else
    redirect '/'
  end
end

get '/admin' do
  unless logged_in?
    session[:redirect] = request.url
    redirect '/join'
  end

  unless shikakun?
    redirect '/'
  end

  @brothers = Brother.order("id desc").all

  haml :admin
end

post '/admin/:action' do |action|
  unless logged_in? || shikakun?
    redirect '/'
  end

  if action === 'new'
    Brother.create({:screen_name => params[:screen_name]})
  elsif action === 'delete'
    Brother.find(params[:id]).destroy
  end

  redirect '/admin'
end
