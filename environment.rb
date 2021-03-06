ENV['APP_ENV'] ||= 'development'

require 'active_record'
require 'date'
require 'sentry-raven'

if ENV['RAVEN_DSN']
  Raven.configure do |config|
    config.dsn = ENV['RAVEN_DSN']
  end
end

# helper classes:
require_relative './lib/court_schedule_scraper.rb'
require_relative './lib/schedule_updater.rb'
require_relative './lib/schedule_reminder.rb'
require_relative './lib/differ.rb'
require_relative './lib/twilio_client.rb'

# models:
require_relative './models/schedule.rb'
require_relative './models/subscription.rb'
require_relative './models/change_log.rb'
