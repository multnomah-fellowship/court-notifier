require 'spec_helper'

def set_env(env, value, &block)
  before, ENV[env] = ENV[env], value

  begin
    block.call
  ensure
    ENV[env] = before
  end
end

RSpec.describe TwilioClient do
  let(:messages_resource) { double }
  let(:client) { double(messages: messages_resource) }
  let(:client_class) { double(new: client) }

  subject { TwilioClient.new(client_class: client_class) }

  describe '#initialize' do
    let(:account_sid) { 'account_sid' }
    let(:auth_token) { 'auth_token' }

    around do |example|
      set_env('TWILIO_ACCOUNT_SID', account_sid) do
        set_env('TWILIO_AUTH_TOKEN', auth_token) do
          example.run
        end
      end
    end

    it 'instantiates the client with the value of environment variables' do
      expect(client_class).to receive(:new)
        .with(account_sid, auth_token)

      subject
    end
  end

  describe '#send_updated_message' do
    let(:schedule) { FactoryGirl.create(:schedule) }
    let(:phone_number) { '+13305551234' }
    let(:new_datetime) { Time.now }

    before do
      schedule.datetime = new_datetime
    end

    it 'sends a message that looks roughly correct' do
      expect(messages_resource)
        .to receive(:create)
        .with(hash_including(
          body: match(/datetime changed/),
          to: phone_number
        ))

      subject.send_updated_message(phone_number, schedule)
    end
  end

  describe '#send_created_message' do
    let(:schedule) { FactoryGirl.create(:schedule) }
    let(:phone_number) { '+13305551234' }

    it 'sends a message to the right person' do
      expect(messages_resource)
        .to receive(:create)
        .with(hash_including(
          body: match(/New event/),
          to: phone_number
        ))

      subject.send_created_message(phone_number, schedule)
    end

    it 'templates the datetime properly' do
      expect(messages_resource)
        .to receive(:create)
        .with(hash_including(
          body: match(%r{5/30/17 11:30am}),
        ))

      subject.send_created_message(phone_number, schedule)
    end
  end

  describe '#send_deleted_message' do
    let(:schedule) { FactoryGirl.create(:schedule) }
    let(:phone_number) { '+13305551234' }

    it 'sends a message to the right person' do
      expect(messages_resource)
        .to receive(:create)
        .with(hash_including(
          body: match(/Removed event/),
          to: phone_number
        ))

      subject.send_deleted_message(phone_number, schedule)
    end
  end
end
