require 'sinatra'
require 'sinatra/contrib'
require "sinatra/reloader" if development?

get '/' do
  "hello world"
end
