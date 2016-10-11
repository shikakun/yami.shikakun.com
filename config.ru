require 'bundler'
Bundler.require

require './app'

use ActiveRecord::ConnectionAdapters::ConnectionManagement

run Sinatra::Application
