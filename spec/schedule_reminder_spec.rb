require 'spec_helper'

describe ScheduleReminder do
  describe '#remind' do
    context 'with a subscription' do
      let(:schedule) { FactoryGirl.create(:schedule) }
      let(:subscription) do
        FactoryGirl.create(:subscription, case_number: schedule.case_number)
      end

      before do
        allow_any_instance_of(TwilioClient).
          to receive(:send_reminder_message)
      end

      context 'when the event is happening in the range' do
        let(:range) { ((schedule.datetime - 1)..(schedule.datetime + 1)) }

        it 'reminds the user' do
          expect_any_instance_of(TwilioClient).to receive(:send_reminder_message).with(subscription.phone_number, schedule).once

          ScheduleReminder.new(range).remind
        end
      end

      context 'when the event is happening outside the range' do
        let(:range) { ((schedule.datetime + 1)..(schedule.datetime + 2)) }

        it 'does not remind the user' do
          expect_any_instance_of(TwilioClient).not_to receive(:send_reminder_message)

          ScheduleReminder.new(range).remind
        end
      end
    end
  end
end
