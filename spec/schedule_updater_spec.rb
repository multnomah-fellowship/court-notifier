require 'spec_helper'

SCHEDULE_FIXTURE = {
  case_number: '17CR1234',
  schedule_type: 'Offense Felony',
  style: "State of Oregon\nvs.\nJohn Doe",
  judicial_officer: 'Judge Cool Person',
  physical_location: 'Courthouse 123',
  datetime: Time.now,
  hearing_type: 'Arraignment',
}

RSpec.describe ScheduleUpdater do
  let(:client) { double() }
  let(:date) { Date.today }

  subject { described_class.new(date, client: client) }

  describe '#fetch_schedules' do
    before do
      allow_any_instance_of(CourtScheduleScraper)
        .to receive(:cases_for)
        .and_return([])
    end

    it 'fetches the right days' do
      # just look at both ends: today and two weeks henceforth
      expect_any_instance_of(CourtScheduleScraper)
        .to receive(:cases_for)
        .with(date)

      expect_any_instance_of(CourtScheduleScraper)
        .to receive(:cases_for)
        .with(date + 14)

      subject.fetch_schedules
    end

    context 'when the scraper returns items for one day' do
      before do
        allow_any_instance_of(CourtScheduleScraper)
          .to receive(:cases_for)
          .with(date)
          .and_return([SCHEDULE_FIXTURE])
      end

      it 'returns an array of items' do
        expect(subject.fetch_schedules)
          .to match_array([SCHEDULE_FIXTURE])
      end
    end
  end

  describe '#update' do
    before do
      allow(subject).to receive(:fetch_schedules)
        .and_return(fetched_schedules)
    end

    context 'when the fetched schedules are empty' do
      let(:fetched_schedules) { [] }

      it 'deletes a schedule in the update window' do
        FactoryGirl.create(:schedule, datetime: date + 1)

        expect { subject.update }
          .to change { Schedule.count }.from(1).to(0)
      end

      it 'does not delete an old schedule' do
        FactoryGirl.create(:schedule, datetime: date - 1)

        expect { subject.update }
          .not_to change { Schedule.count }
      end
    end

    context 'when there is a fetched schedule' do
      let(:fetched_schedules) { [SCHEDULE_FIXTURE] }

      it 'creates a schedule instance' do
        expect { subject.update }
          .to change { Schedule.count }.from(0).to(1)
      end
    end
  end
end
