require 'twilio-ruby'

class TwilioClient
  def initialize(sid = ENV['TWILIO_ACCOUNT_SID'], token = ENV['TWILIO_AUTH_TOKEN'])
    @client = Twilio::REST::Client.new(sid, token)
  end

  def send_reminder_message(phone, schedule)
    @client.messages.create(
      from: '+14152126085',
      to: phone,
      body: "Reminder! Case #{schedule.case_number} has a #{schedule.hearing_type} at #{schedule.datetime}."
    )
  end

  def send_updated_message(phone, schedule)
    changes = schedule.changes.map do |field, (before, after)|
      "#{field} changed #{before} -> #{after}"
    end.join(',')

    @client.messages.create(
      from: '+14152126085',
      to: phone,
      body: "Update for case #{schedule.case_number}: #{changes}"
    )
  end

  def send_created_message(phone, new_schedule)
    @client.messages.create(
      from: '+14152126085',
      to: phone,
      body: "Update for case #{new_schedule.case_number}: new event: #{new_schedule.attributes}"
    )
  end

  def send_deleted_message(phone, removed_schedule)
    @client.messages.create(
      from: '+14152126085',
      to: phone,
      body: "Update for case #{removed_schedule.case_number}: removed event: #{removed_schedule.attributes}"
    )
  end
end
