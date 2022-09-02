require 'rails_helper'

RSpec.describe MessageMailer, type: :mailer do
  describe '#new_message_email' do
    let(:subscriber) { create(:subscriber, email: 'reader@example.com') }
    let(:message) { create(:message, text: 'There is hope.') }
    let(:mail) { described_class.with(subscriber: subscriber, message: message).new_message_email }

    it 'is addressed to the subscriber' do
      expect(mail.to).to eq(['reader@example.com'])
    end

    it 'uses the configured subject and sender' do
      expect(mail.subject).to eq(described_class::SUBJECT)
      expect(mail.from).to eq([ENV.fetch('MAILER_FROM_ADDRESS', 'no-reply@cope-notes.example')])
    end

    it 'includes the message text in both parts' do
      expect(mail.html_part.body.to_s).to include('There is hope.')
      expect(mail.text_part.body.to_s).to include('There is hope.')
    end

    it 'greets the subscriber by name in both parts' do
      subscriber.update!(name: 'Robin')

      expect(mail.html_part.body.to_s).to include('Hi Robin,')
      expect(mail.text_part.body.to_s).to include('Hi Robin,')
    end

    it 'renders exactly one HTML document, not a layout wrapped around another' do
      expect(mail.html_part.body.to_s.scan('<html').size).to eq(1)
    end
  end
end
