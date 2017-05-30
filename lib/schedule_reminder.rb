class ScheduleReminder
  def initialize(range)
    @range = range
    @client = TwilioClient.new
  end

  def remind
    Schedule
      .joins(:subscriptions)
      .includes(:subscriptions)
      .where(datetime: @range).find_each do |schedule|
      schedule.subscriptions.each do |subscription|
        @client.send_reminder_message(subscription.phone_number, schedule)
      end
    end
  end
end
