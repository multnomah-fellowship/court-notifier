class ScheduleUpdater
  DAYS_TO_UPDATE = 14

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

    Schedule.transaction do
      Differ.new(old_schedules, new_schedules).each_change do |change_type, *change|
        case change_type
        when :created
          # `change` is the new event's attributes
          schedule = Schedule.create(change[0])
          handle_schedule_create(schedule)
        when :removed
          # `change` is the old event's attributes
          schedule = Schedule.find(change[0][:id])
          handle_schedule_removed(schedule)
          schedule.destroy
        when :changed
          # `change` is a 2-tuple of the id and an activemodel-style change hash like:
          #   `{ key => [before, after] }`
          id, attribute_changes = change
          schedule = Schedule.find(id)
          attribute_changes.each do |key, (_, after)|
            schedule[key] = after
          end
          handle_schedule_update(schedule, attribute_changes)
          schedule.save
        end
      end
    end
  end

  private

  def handle_schedule_update(schedule, changes)
    $stderr.puts "Schedule updated: #{schedule.case_number}\t\t#{changes}"

    ChangeLog.create(
      case_number: schedule.case_number,
      change_type: :changed,
      change_contents: changes
    )

    Subscription
      .where(case_number: schedule.case_number)
      .find_each do |subscription|
      @client.send_updated_message(subscription.phone_number, schedule)
    end
  end

  def handle_schedule_removed(schedule)
    $stderr.puts("Schedule removed: #{schedule.case_number}")

    ChangeLog.create(
      case_number: schedule.case_number,
      change_type: :removed,
      change_contents: schedule
    )

    Subscription
      .where(case_number: schedule.case_number)
      .find_each do |subscription|
      @client.send_deleted_message(subscription.phone_number, schedule)
    end
  end

  def handle_schedule_create(schedule)
    $stderr.puts("Schedule created: #{schedule.case_number}")

    ChangeLog.create(
      case_number: schedule.case_number,
      change_type: :created,
      change_contents: schedule
    )

    Subscription
      .where(case_number: schedule.case_number)
      .find_each do |subscription|
      @client.send_created_message(subscription.phone_number, schedule)
    end
  end
end
