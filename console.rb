require_relative './environment.rb'

ActiveRecord::Base.establish_connection(ENV['DATABASE_URL'])

require 'pry'
binding.pry
