require 'sinatra'
require 'mysql2'
require 'erb'

get '/' do
  	client = Mysql2::Client.new(host: "0.0.0.0", username: "root", password: 'root', database: 'connecple')
  	results = client.query("SELECT * FROM comment")
  	@ary = Array.new
  	results.each {|row| @ary << row}
  	erb :comment
end

post '/main' do
 	client = Mysql2::Client.new(host: "0.0.0.0", username: "root", password: 'root', database: 'connecple')
  	client.query("INSERT INTO comment (user_name,comment,user_id) VALUES ('#{params['user_name']}','#{params['comment']}','#{params['user_id']}')")
 	results = client.query("SELECT * FROM comment")
	@ary = Array.new
	results.each {|row| @ary << row}
	erb :comment
end