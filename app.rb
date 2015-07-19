require 'sinatra'

require 'haml'

configure :production do
  set :GOOGLE_DRIVE_CLIENT_ID, ENV['GOOGLE_DRIVE_CLIENT_ID']
end

configure :development do
  set :GOOGLE_DRIVE_CLIENT_ID, '966231612988-cmob8calt2b646p4sddlb4410q2eekmq.apps.googleusercontent.com'
end

get '/' do
  @GOOGLE_DRIVE_CLIENT_ID = settings.GOOGLE_DRIVE_CLIENT_ID
  erb :index
end
