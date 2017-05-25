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
    $logger.puts "Running #{job}"

    case job
    when 'scrape'
      ScheduleUpdater.new(today).update
    end
  end

  # only scrape during business hours
  every(1.hours, 'scrape', at: %w[07:00 09:00 11:00 13:00 15:00 17:00 19:00], if: -> { !today.on_weekend? })
end
