class ScheduleUpdater
  def initialize(date)
    @date = date
    @client = TwilioClient.new
  end


  def update
    (@date..(@date + 7)).each do |date|
      $stderr.puts "Updating schedules for #{date}..."

      Schedule.transaction do
        beginning_schedules = Schedule.on_date(date).pluck(:id)

        cases = CourtScheduleScraper.new.cases_for(date)
        cases.each do |item|
          begin
            datetime = DateTime.strptime("#{item[:date]} #{item[:time]}", "%m/%d/%Y %l:%M %p")
          rescue ArgumentError
            raise ArgumentError.new("Invalid DateTime: #{item[:date]} #{item[:time]}")
          end

          # TODO: sometimes two hearings are scheduled with all fields equal
          # except the datetime. What is the right thing to do with that?

          schedule = Schedule.on_date(date).where(
            case_number: item[:case_number],
            hearing_type: item[:hearing_type],
          ).first_or_initialize

          schedule.datetime = datetime
          schedule.schedule_type = item[:type]
          schedule.style = item[:style]
          schedule.judicial_officer = item[:judicial_officer]
          schedule.physical_location = item[:physical_location]

          if schedule.persisted?
            if schedule.changed?
              send_update_messages(schedule)
              schedule.save
            end

            beginning_schedules.delete(schedule.id)
          else
            schedule.save
            send_created_messages(schedule)
          end
        end

        beginning_schedules.each do |id|
          schedule = Schedule.find(id)
          send_deleted_messages(schedule)
        end

        Schedule.where(id: beginning_schedules).destroy_all
      end
    end
  end

  private

  def send_update_messages(schedule)
    $stderr.puts "Schedule updated: #{schedule.case_number}\t\t#{schedule.changes}"

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
