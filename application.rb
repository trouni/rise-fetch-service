# frozen_string_literal: true
$stdout.sync = true

require 'rubygems'
require 'bundler/setup'
require 'sinatra'
require 'json'
require 'sinatra/run-later'

require File.join(File.dirname(__FILE__), 'environment')

configure do
  set :views, "#{File.dirname(__FILE__)}/views"
  set :show_exceptions, :after_handler
end

configure :production, :development do
  enable :logging
end

helpers do
  # add your helpers here
end

# root page
get '/' do
  erb :root
end

post '/api/fetch-users' do
  # run_later do
    params = JSON.parse(request.body.read)
    RiseAPI.fetch_users(params['users'])
  # end
  { ok: true }.to_json
end
