require 'twilio-ruby'

class TwilioClient
  def initialize(sid: ENV['TWILIO_ACCOUNT_SID'],
                 token: ENV['TWILIO_AUTH_TOKEN'],
                 client_class: Twilio::REST::Client)
    @client = client_class.new(sid, token)
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
    datetime_string = new_schedule.datetime.strftime('%-m/%-d/%y %-I:%M%P')
    style_string = new_schedule.style.gsub(/\n/, ' ')
    message_format =
      'New event for case %{case_number} (%{style}): %{hearing_type} at %{datetime}'

    @client.messages.create(
      from: '+14152126085',
      to: phone,
      body: message_format % new_schedule.attributes.symbolize_keys.merge(
        datetime: datetime_string,
        style: style_string,
      )
    )
  end

  def send_deleted_message(phone, removed_schedule)
    @client.messages.create(
      from: '+14152126085',
      to: phone,
      body: "Removed event for case #{removed_schedule.case_number}: #{removed_schedule.attributes}"
    )
  end
end
