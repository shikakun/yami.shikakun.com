require 'sinatra'
require 'sinatra/contrib'
require "sinatra/reloader" if development?
require 'hamlit'

set :haml, format: :html5

get '/' do
  haml :index
end
