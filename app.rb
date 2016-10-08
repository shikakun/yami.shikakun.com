require 'sinatra'
require 'sinatra/contrib'
require "sinatra/reloader" if development?
require 'sinatra/flash'
require 'hamlit'
require 'dotenv'
require 'omniauth-twitter'
require 'twitter'
require 'irkit'

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

  def twitter
    Twitter::REST::Client.new do |config|
      config.consumer_key        = ENV['TWITTER_CONSUMER_KEY']
      config.consumer_secret     = ENV['TWITTER_CONSUMER_SECRET']
      config.access_token        = ENV['TWITTER_SHIKAKUN_TOKEN']
      config.access_token_secret = ENV['TWITTER_SHIKAKUN_TOKEN_SECRET']
    end
  end
end

get '/' do
  haml :index
end

get '/hikari', '/yami' do
  unless logged_in?
    session[:redirect] = request.url
    redirect '/join'
  end

  param = request.path_info

  if param === '/hikari'
    session[:lighting_status] = true
    irdata = IRKit::App::Data['IR']['lighting_on']
    message = "@#{session[:screen_name]} が鹿の自宅の照明を点けました"
  elsif param === '/yami'
    session[:lighting_status] = false
    irdata = IRKit::App::Data['IR']['lighting_off']
    message = "@#{session[:screen_name]} が鹿の自宅の照明を消しました"
  else
    redirect '/'
  end

  flash[:message] = message

  irkit = IRKit::InternetAPI.new(clientkey: ENV['IRKIT_CLIENTKEY'], deviceid: ENV['IRKIT_DEVICEID'])
  res = irkit.post_messages(irdata)
  case res.code
  when 200
  redirect '/'
  else
    raise res
  end
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
