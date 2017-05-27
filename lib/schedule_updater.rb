class ScheduleUpdater
  DAYS_TO_UPDATE = 7

  def initialize(date)
    @date = date
    @client = TwilioClient.new
  end


  def update
    old_schedules =
      Schedule.on_or_after(@date).map(&:attributes).map(&:symbolize_keys)
    new_schedules = []

    (@date..(@date + DAYS_TO_UPDATE)).each do |date|
      $stderr.write "Fetching schedules for #{date}..."
      cases = CourtScheduleScraper.new.cases_for(date).to_a
      $stderr.puts " #{cases.length}"

      new_schedules.concat(cases)
    end

    require 'pry'; binding.pry

    Differ.new(old_schedules, new_schedules).each_change do |change_type, change|
      case change_type
      when :created
        # `change` is the new event's attributes
        schedule = Schedule.create(change)
        send_created_messages(schedule)
      when :removed
        # `change` is the old event's attributes
        schedule = Schedule.find(change[:id])
        send_deleted_messages(schedule)
        schedule.destroy
      when :changed
        # `change` is a 2-tuple of the id and an activemodel-style change hash like:
        #   `{ key => [before, after] }`
        id, attribute_changes = change
        schedule = Schedule.find(id)
        attribute_changes.each do |key, (_, after)|
          schedule[key] = after
        end
        send_update_messages(schedule)
        schedule.save
      end
    end
  end

  private

  def send_update_messages(schedule, changes)
    $stderr.puts "Schedule updated: #{schedule.case_number}\t\t#{changes}"

    Subscription
      .where(case_number: schedule.case_number)
      .find_each do |subscription|
      @client.send_updated_message(subscription.phone_number, schedule)
    end
  end

  def send_deleted_messages(schedule)
    $stderr.puts("Schedule destroyed: #{schedule.case_number}")

    Subscription
      .where(case_number: schedule.case_number)
      .find_each do |subscription|
      @client.send_deleted_message(subscription.phone_number, schedule)
    end
  end

  def send_created_messages(schedule)
    $stderr.puts("Schedule created: #{schedule.case_number}")

    Subscription
      .where(case_number: schedule.case_number)
      .find_each do |subscription|
      @client.send_created_message(subscription.phone_number, schedule)
    end
  end
end
