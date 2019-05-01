require 'sinatra'
require 'mysql2'
require 'erb'
require 'securerandom'
require 'digest/sha1'
require 'redis'
require 'sinatra/cookies'

#sinatoraでセッションを使うためのお作法
configure do
  enable :sessions
end

#タイムアウト用の変数
timeOut = 3600

get '/home' do
  #cookiesからsession_idを格納、なければ再ログイン
  session_id = cookies[:session]
  if session_id.nil?
    redirect '/'
  end

  #RedisにセッションIDがなければ再ログインさせる
  user_id = get_redis.get(session_id)
  if user_id.nil? or user_id.empty?
    redirect '/'
  end

  results = get_client.query("SELECT * FROM user WHERE unique_name = '#{user_id}'")
  ary = Array.new
  results.each {|row| ary << row}
  @user = ary[0]

  results = get_client.query("SELECT * FROM user INNER JOIN comment ON user.id = comment.user_id")
  @ary = Array.new
  results.each {|row| @ary << row}
  erb :comment

  # results = get_client.query("SELECT * FROM comment")
  # @ary = Array.new

  # results.each do |row|
  #   @ary << row
  # end
  # erb :comment
end

#コメント画面
post '/home' do
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
get '/' do
  results = get_client.query("SELECT * FROM user")
  @ary = Array.new
  results.each {|row| @ary << row}
  @message = session[:message]
  session[:message] = nil
  erb :sign_in
end

#サインインの整合性確認
post '/' do
  results = get_client.query("SELECT * FROM user WHERE display_name = '#{params['name']}'")
  ary = Array.new
  results.each {|row| ary << row}
  @user = ary[0]
  puts @user

  #'/'にリダイレクトした際にメッセージを流用するため
  #ユーザ名で検索を行い、いなかったらログインページにリダイレクト
  if @user.nil?
    session[:message] = "パスワードとユーザ名が間違っています"
    redirect '/'
  end

  #パスワードの認証 ログイン時に入力したパスワードと登録されているsoltを繋げた文字列がDBの暗号化したパスワードと一致していればtrue
  if @user['password'] != Digest::SHA1.hexdigest("#{params['password']},#{@user['pass_solt']}")
    session[:message] = "パスワードとユーザ名が間違っています"
    redirect '/'
  end

  #セッションID用に16桁の文字列を発行
  session_id = SecureRandom.alphanumeric(16)

  #CokkiesにセッションIDを登録
  cookies[:session] = session_id

  #Redisにuser_idのセッション情報を保存
  #Redisの構造 -> (キー, 値)
  get_redis.setex(session_id, timeOut, @user['unique_name'])

  #ログインに成功したらuserのマイページにリダイレクトする
  redirect '/home'
end

get '/user/:unique_name' do
    results = get_client.query("SELECT * FROM user WHERE unique_name = '#{params['unique_name']}'")
    ary = Array.new
    results.each {|row| ary << row}
    @user = ary[0]

    if @user.nil?
      status 404 #404ファイルをクライアントに返す
      return
    else
      @name = @user['display_name']
    end

    erb :user
end

get '/logout' do
  #Cookiesに登録されているキーを参照しRedis側で削除
  get_redis.del(cookies[:session])
  session[:message] = "ログアウトしました。"
  redirect '/'
end

def get_client
  Mysql2::Client.new(host: "0.0.0.0", username: "root", password: 'root', database: 'connecple')
end

def get_redis
  Redis.new(:host => "127.0.0.1", :port => 6379)
end
