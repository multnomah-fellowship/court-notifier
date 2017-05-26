require 'clockwork'
require 'tzinfo'
require_relative './environment.rb'

$logger = Logger.new($stdout)

def today
  tz = TZInfo::Timezone.get('America/Los_Angeles')
  tz.utc_to_local(Time.now.utc).to_date
end

module Clockwork
  handler do |job|
    $logger.info "Running #{job}"

    case job
    when 'scrape'
      ActiveRecord::Base.establish_connection(ENV['DATABASE_URL'])
      ScheduleUpdater.new(today).update
    end
  end

  # only scrape during business hours
  # 7 AM PDT = 2 PM UTC
  # 5 PM PDT = 12 AM UTC
  every(1.hours, 'scrape', at: %w[14:00 16:00 18:00 20:00 22:00 00:00 02:00])
end
