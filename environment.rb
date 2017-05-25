ENV['APP_ENV'] ||= 'development'

require 'active_record'
require 'date'

require_relative './lib/court_schedule_scraper.rb'
require_relative './lib/schedule_updater.rb'
require_relative './lib/schedule.rb'
