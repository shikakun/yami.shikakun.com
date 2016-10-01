require 'sinatra'
require 'sinatra/contrib'
require "sinatra/reloader" if development?
require 'sinatra/flash'
require 'hamlit'
require 'dotenv'
require 'omniauth-twitter'
require 'twitter'

set :haml, format: :html5
Dotenv.load

enable :sessions
set :session_secret, ENV['SESSION_SECRET']

configure do
  enable :sessions
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

get '/lighting/:switch' do
  unless logged_in?
    session[:redirect] = request.url
    redirect '/join'
  end

  if params['switch'] === 'on'
    session[:lighting_status] = true;
    message = "@#{session[:screen_name]} が鹿の自宅の照明を点けました"
  elsif params['switch'] === 'off'
    session[:lighting_status] = false;
    message = "@#{session[:screen_name]} が鹿の自宅の照明を消しました"
  end

  flash[:message] = message
  redirect '/'
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
