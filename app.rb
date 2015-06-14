require 'sinatra'

require 'haml'

get '/' do
  @mes = 'Hello'
  erb :index
end
