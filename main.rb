require 'sinatra'
require 'mysql2'
require 'erb'
require 'securerandom'
require 'digest/sha1'


get '/' do
  	client = Mysql2::Client.new(host: "0.0.0.0", username: "root", password: 'root', database: 'connecple')
  	results = client.query("SELECT * FROM comment")
  	@ary = Array.new
  	results.each {|row| @ary << row}
  	erb :comment
end

#メインメニュー
post '/main' do
 	client = Mysql2::Client.new(host: "0.0.0.0", username: "root", password: 'root', database: 'connecple')
	client.query("INSERT INTO comment (user_name,comment,user_id) VALUES ('#{params['user_name']}','#{params['comment']}','#{params['user_id']}')")
 	results = client.query("SELECT * FROM comment")
	@ary = Array.new
	results.each {|row| @ary << row}
	erb :comment
end

#新規登録画面の取得
get '/user_newSignup' do
  erb :newSign_up
end

#新規登録画面
post '/user_newSignup' do
  client = Mysql2::Client.new(host: "0.0.0.0", username: "root", password: 'root', database: 'connecple')

  #パスワードのハッシュ化に伴いソルト生成
  userSolt = SecureRandom.alphanumeric(16)
  convertHashPass = Digest::SHA1.hexdigest("#{params['password']},#{userSolt}")
  client.query("INSERT INTO user (name,password,user_id,pass_solt) VALUES ('#{params['name']}','#{convertHashPass}','#{params['user_id']}','#{userSolt}')")
  erb :newSign_up
end

#サインアップ時のerbファイルを取得
get '/user_signup' do
  erb :sign_up
end

#サインアップの整合性確認
post '/user_signup' do
  client = Mysql2::Client.new(host: "0.0.0.0", username: "root", password: 'root', database: 'connecple')
  @results = client.query("SELECT name,password,pass_solt FROM user")
  results.each do |dbUserData|
  puts dbUserData
  end
end

