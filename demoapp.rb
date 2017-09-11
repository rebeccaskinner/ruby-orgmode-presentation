#!/usr/bin/env ruby
require 'sinatra'
require 'json'

set :port, 8888
set :bind, "0.0.0.0"

def letters
  Array('a'..'z') + Array('A'..'Z')
end

def numbers
  Array('0'..'9')
end

def symbols
  "!@#$%^&*()_[]{}".chars
end

def dict
  letters + numbers + symbols
end

def rand_str cnt
  x = []
  cnt.times do x << dict.sample end
  x.reduce(&:+)
end

def rand_letters cnt
  x = []
  cnt.times do x << letters.sample end
  x.reduce(&:+)
end

class FSOperation
  attr_reader :file,:timestamp
  def initialize
    @file = rand_path
    @timestamp = rand_time
  end
  def to_json *a
    {
      "file" => file,
      "timestamp" => @timestamp.to_s
    }.to_json(*a)
  end
end

def rand_time start = 0.0
  Time.at(rand(Time.at(start) .. Time.now))
end

def rand_path pfx=""
  len = rand(5..25)
  path = "#{pfx}/#{rand_letters len}"
  if [true,false].sample
    return (rand_path path)
  end
  path
end

class User
  attr_accessor :name
  attr_accessor :password1, :password2
  attr_accessor :actions

  def initialize
    @name = rand_letters 25
    @password1 = rand_str 6
    @password2 = @password1
    ## There's a 20% chance the users's password2 won't match their password1
    if [false,false,false,false,true].sample
      @password2 = rand_str 6
    end
    @actions = []
    rand(5..25).times do
      @actions << FSOperation.new
    end
  end

  def fork *attrs
    n = User.new
    n.name = @name unless attrs.include? :name
    n.password1 = @password1 unless attrs.include? :password1
    n.password2 = @password2 unless attrs.include? :password2
    n.actions = @actions  unless attrs.include? :actions
    n
  end

  def to_json *a
    {
      "username" => @name,
      "key" => @password1,
      "pw" => @password2,
      "activity" => @actions.map(&:to_json),
    }.to_json(*a)
  end

  def valid?
    @password1 == @password2
  end
end

users = {1 => Hash.new, 2 => Hash.new}

10.times do
  u = User.new
  users[1][u.name] = u
  changes = [:ok,:ok,:ok,:ok,:ok,:newuser,:newuser,:actions,:ua,:pw].sample
  if changes == :ok
    users[2][u.name] = u
    next
  end
  args = case changes
         when :newuser then [:name]
         when :actions then [:action]
         when :ua then [:action,:name]
         when :pw then [:action, :password1]
         else []
         end
  u2 = u.fork(*args)
  users[2][u2.name] = u2
end

get '/users' do
  all_users = users[1].keys + users[2].keys
  headers "content-type" => "application/json"
  all_users.uniq.to_json
end

get '/:num/users' do
  n = params['num'].to_i
  unless [1,2].include? n.to_i
    puts "num isn't a known server endpoint (should be 1 or 2)"
    status 404
    return
  end
  names = users[n].keys
  headers "content-type" => "application/json"
  names.to_json
end

get '/:num/:user' do
  n = params['num'].to_i
  unless [1,2].include? n.to_i
    puts "num isn't a known server endpoint (should be 1 or 2)"
    status 404
    return
  end
  u = users[n][params['user']]
  if u.nil?
    puts "username is unknown"
    status 404
    return
  end
  headers "content-type" => "application/json"
  u.to_json
end
