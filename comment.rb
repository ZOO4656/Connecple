# require 'sinatra'
# require 'mysql2'
# require 'erb'
# require 'redis'
# require 'sinatra/cookies'
require './main'

get '/comment' do
	erb :comment
end