require 'sinatra'
require 'sinatra/contrib'
require "sinatra/reloader" if development?
require 'hamlit'
require 'dotenv'

set :haml, format: :html5
Dotenv.load

get '/' do
  haml :index
end
