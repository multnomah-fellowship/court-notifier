require 'clockwork'
require 'tzinfo'
require_relative './environment.rb'

$logger = Logger.new($stdout)

def today
  tz = TZInfo::Timezone.get('America/Los_Angeles')
  tz.utc_to_local(Time.now.utc).to_date
end

module Clockwork
  ONE_HOUR = 60 * 60
  ONE_DAY = 24 * 60 * 60

  handler do |job|
    $logger.info "Running #{job}"

    case job
    when 'scrape'
      ActiveRecord::Base.establish_connection(ENV['DATABASE_URL'])
      ScheduleUpdater.new(today).update
    when 'remind'
      range = ((Time.now + ONE_DAY)..(Time.now + ONE_DAY + ONE_HOUR))
      ScheduleReminder.new(range).remind
    end
  end

  # only scrape during business hours
  # 7 AM PDT = 2 PM UTC
  # 5 PM PDT = 12 AM UTC
  every(1.hours, 'scrape', at: %w[14:00 16:00 18:00 20:00 22:00 00:00 02:00])

  # send reminders of court cases for any event happening just over 24 hours
  # from then. E.g. at 5pm Thursday send reminders for events happening between
  # 5-6pm on Friday.
  every(1.hours, 'remind')
end
