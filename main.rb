require 'sinatra'
require 'mysql2'
require 'erb'
require 'securerandom'
require 'digest/sha1'

#sinatoraでセッションを使うためのお作法
configure do
  enable :sessions
end

get '/' do
	results = get_client.query("SELECT * FROM comment")
	@ary = Array.new
	results.each {|row| @ary << row}
	erb :comment
end

#メインメニュー
post '/main' do
	get_client.query("INSERT INTO comment (user_name,comment,user_id) VALUES ('#{params['user_name']}','#{params['comment']}','#{params['user_id']}')")
 	results = client.query("SELECT * FROM comment")
	@ary = Array.new
	results.each {|row| @ary << row}
	erb :comment
end

#新規登録画面の取得
get '/user_signup' do
  erb :sign_up
end

#新規登録画面
post '/user_signup' do
  #パスワードのハッシュ化に伴いソルト生成
  userSolt = SecureRandom.alphanumeric(16)
  convertHashPass = Digest::SHA1.hexdigest("#{params['password']},#{userSolt}")
  get_client.query("INSERT INTO user (name,password,user_id,pass_solt) VALUES ('#{params['name']}','#{convertHashPass}','#{params['user_id']}','#{userSolt}')")
  session[:user_id] = params['user_id']
  redirect '/user'
end

#サインアップ時のerbファイルを取得
get '/user_signin' do
  results = get_client.query("SELECT * FROM user")
  @ary = Array.new
  results.each {|row| @ary << row}
  @message = session[:message]
  erb :sign_in
end

#サインアップの整合性確認
post '/user_signin' do
  results = get_client.query("SELECT * FROM user WHERE name = '#{params['name']}'")
  ary = Array.new
  results.each {|row| ary << row}
  @user = ary[0]
  if @user.nil?
    session[:message] = "パスワードとユーザ名が間違っています"
    redirect '/user_signin'
  end

  if @user['password'] != Digest::SHA1.hexdigest("#{params['password']},#{@user['pass_solt']}")
    session[:message] = "パスワードとユーザ名が間違っています"
    redirect '/user_signin'
  end

  puts Digest::SHA1.hexdigest("#{params['password']},#{@user['pass_solt']}")
  puts params['password']

  #セッションにuser_idを記憶させる。セッションはメモリに残っているためサーバ落としたら全員ログアウト
  session[:user_id] = @user['user_id']

  #ログインに成功したらuserのマイページにリダイレクトする
  redirect '/user'
end

get '/user' do
  #sessionのuser_idを変数に格納
  user_id = session[:user_id]
  if user_id.nil?
    redirect '/user_signin'
  end

  results = get_client.query("SELECT * FROM user WHERE user_id = '#{user_id}'")
  ary = Array.new
  results.each {|row| ary << row}
  @user = ary[0]
  erb :user
end

get '/logout' do
  session.clear
  redirect '/user_signin'
end

def get_client
  Mysql2::Client.new(host: "0.0.0.0", username: "root", password: 'root', database: 'connecple')
end
