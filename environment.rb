ENV['APP_ENV'] ||= 'development'

require 'active_record'
require 'date'

# helper classes:
require_relative './lib/court_schedule_scraper.rb'
require_relative './lib/schedule_updater.rb'
require_relative './lib/schedule_reminder.rb'
require_relative './lib/differ.rb'

# models:
require_relative './lib/schedule.rb'
require_relative './lib/subscription.rb'
require_relative './lib/twilio_client.rb'
