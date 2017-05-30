require 'spec_helper'

RSpec.describe Differ do
  def sample_event(**overrides)
    {
      id: 1234,
      case_number: '14CR20076',
      type: 'Offense Felony',
      style: "State of Oregon\n" + "vs\n" + "Brian Garth Weese",
      datetime: Time.new(2017, 5, 26, 10, 14, 0),
      judicial_officer: 'Greenlick, Michael A',
      physical_location: 'Courtroom 328',
      hearing_type: 'Hearing - Drug Court'
    }.merge(overrides)
  end

  def sample_event_after(**overrides)
    sample_event(**overrides).tap do |event|
      event.delete(:id)
    end
  end

  describe '#each_change' do
    subject { described_class.new(before, after).each_change.to_a }

    context 'when an event has a changed style' do
      let(:before) { [sample_event(style: 'before')] }
      let(:after) { [sample_event_after(style: 'after')] }

      it 'returns a change event with the style' do
        expect(subject).to eq([
          [:changed, before[0][:id], { style: ['before', 'after'] }]
        ])
      end
    end

    context 'when an event has a changed location or judge' do
      context 'with just a changed location' do
        let(:before) { [sample_event(physical_location: 'before')] }
        let(:after) { [sample_event_after(physical_location: 'after')] }

        it 'returns a change event' do
          expect(subject).to eq([
            [:changed, before[0][:id], { physical_location: ['before', 'after'] }]
          ])
        end
      end

      context 'with just a changed judge' do
        let(:before) { [sample_event(judicial_officer: 'before')] }
        let(:after) { [sample_event_after(judicial_officer: 'after')] }

        it 'returns a change event' do
          expect(subject).to eq([
            [:changed, before[0][:id], { judicial_officer: ['before', 'after'] }]
          ])
        end
      end

      context 'with both a changed location and judge' do
        let(:before) do
          [sample_event(
            judicial_officer: 'before',
            physical_location: 'before',
          )]
        end

        let(:after) do
          [sample_event(
            judicial_officer: 'after',
            physical_location: 'after',
          )]
        end

        it 'returns a change event' do
          expect(subject).to eq([
            [:changed, before[0][:id], {
              judicial_officer: ['before', 'after'],
              physical_location: ['before', 'after']
            }]
          ])
        end
      end
    end

    context 'when an event has a changed datetime' do
      let(:before) { [sample_event(datetime: 'before')] }
      let(:after) { [sample_event_after(datetime: 'after')] }

      it 'returns a change event' do
        expect(subject).to eq([
          [:changed, before[0][:id], { datetime: ['before', 'after'] }]
        ])
      end
    end

    context 'when two events are exactly the same' do
      let(:before) { [sample_event] }
      let(:after) { [sample_event_after] }

      it 'returns an empty array' do
        expect(subject).to eq([])
      end
    end

    context 'when a new event is created' do
      let(:before) { [] }
      let(:after) { [sample_event_after] }

      it 'returns an :created event' do
        expect(subject).to eq([[:created, after[0]]])
      end
    end

    context 'when an event is removed' do
      let(:before) { [sample_event] }
      let(:after) { [] }

      it 'returns a :removed event' do
        expect(subject).to eq([[:removed, before[0]]])
      end
    end
  end
end
