class ScheduleUpdater
  def initialize(date)
    @date = date
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

          schedule = Schedule.where(
            case_number: item[:case_number],
            hearing_type: item[:hearing_type],
            datetime: datetime
          ).first_or_initialize

          schedule.schedule_type = item[:type]
          schedule.style = item[:style]
          schedule.judicial_officer = item[:judicial_officer]
          schedule.physical_location = item[:physical_location]

          if schedule.persisted?
            if schedule.changed?
              $stderr.puts "Schedule changed: #{schedule.case_number} #{schedule.changes}"
              schedule.save
            end

            beginning_schedules.delete(schedule.id)
          else
            schedule.save
            $stderr.puts "Schedule created: #{schedule.attributes}"
          end
        end

        beginning_schedules.each do |id|
          $stderr.puts("Schedule destroyed: #{Schedule.find(id)}")
        end

        Schedule.where(id: beginning_schedules).destroy_all
      end
    end
  end
end
