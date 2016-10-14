require 'sinatra'
require 'sinatra/contrib'
require "sinatra/reloader" if development?
require 'active_record'
require 'hamlit'
require 'dotenv'
require 'omniauth-twitter'
require 'twitter'
require 'irkit'

ActiveRecord::Base.establish_connection(ENV['DATABASE_URL'] || 'sqlite3:db/development.db')

twitter_client = Twitter::REST::Client.new do |config|
  config.consumer_key        = ENV['TWITTER_CONSUMER_KEY']
  config.consumer_secret     = ENV['TWITTER_CONSUMER_SECRET']
  config.access_token        = ENV['TWITTER_SHIKAKUN_TOKEN']
  config.access_token_secret = ENV['TWITTER_SHIKAKUN_TOKEN_SECRET']
end

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
    Activity.last.status if Activity.last
  end

  def japanese_status(status)
    case status
    when 'hikari'
      '点け'
    when 'yami'
      '消し'
    end
  end

  def compare_time(before, current)
    diff = current.to_i - before.to_i
    case diff
    when 0
      'あとすぐ'
    when 1..59
      diff.to_s + '秒後に'
    when 60..3540
      (diff / 60).to_i.to_s + '分後に'
    when 3541..82800
      ((diff + 99) / 3600).to_i.to_s + '時間後に'
    when 82801..172000
      '翌日に'
    when 172001..518400
      ((diff + 800) / (60 * 60 * 24)).to_i.to_s + '日後に'
    when 518400..1036800
      '翌週に'
    else
      ((diff + 180000) / (60 * 60 * 24 * 7)).to_i.to_s + '週間後に'
    end
  end
end

class Activity < ActiveRecord::Base
end

class Brother < ActiveRecord::Base
end

get '/' do
  @activities = Activity.order("id asc").all
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
    tweet = "@#{session[:screen_name]} が鹿の自宅の照明を点けました"
    Activity.create({screen_name: session[:screen_name], status: 'hikari'})
  elsif param === '/yami'
    irdata = IRKit::App::Data['IR']['lighting_off']
    tweet = "@#{session[:screen_name]} が鹿の自宅の照明を消しました"
    Activity.create({screen_name: session[:screen_name], status: 'yami'})
  else
    redirect '/'
  end

  twitter_client.update(tweet)

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
    screen_name = params[:screen_name]
    Brother.create({screen_name: screen_name})
    unless screen_name === 'shikakun'
      twitter_client.update("@#{screen_name} が鹿に100円を払いました")
    end
  elsif action === 'delete'
    Brother.find(params[:id]).destroy
  end

  redirect '/admin'
end
