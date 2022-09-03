require 'rails_helper'

RSpec.describe Deliveries::Channels do
  it 'resolves the registered channels' do
    expect(described_class.fetch(:email)).to be_a(Deliveries::Channels::Email)
    expect(described_class.fetch(:log)).to be_a(Deliveries::Channels::Log)
  end

  it 'raises a helpful error for an unregistered channel' do
    expect { described_class.fetch(:carrier_pigeon) }
      .to raise_error(described_class::UnknownChannel, /carrier_pigeon/)
  end

  it 'accepts a new channel without any change to the delivery path' do
    pigeon = Class.new(Deliveries::Channels::Base) do
      def name
        'carrier_pigeon'
      end

      def deliver(subscriber:, note:)
        "pigeon-#{subscriber.id}-#{note.id}"
      end
    end
    described_class.register(:carrier_pigeon, pigeon)
    subscriber = create(:subscriber)
    create(:message)

    result = Deliveries::SendNextNote.call(subscriber, channel: described_class.fetch(:carrier_pigeon))

    expect(result).to be_delivered
    expect(SubscriberEmail.last.channel).to eq('carrier_pigeon')
  ensure
    described_class.registry.delete(:carrier_pigeon)
  end

  describe Deliveries::Channels::Email do
    it 'converts an SMTP connection failure into a transient error' do
      subscriber = create(:subscriber)
      note = create(:message)
      # Action Mailer builds the delivery object internally, so there is no seam
      # to inject here - any_instance is the only way to simulate a dead SMTP host.
      # rubocop:disable RSpec/AnyInstance
      allow_any_instance_of(ActionMailer::MessageDelivery)
        .to receive(:deliver_now).and_raise(Errno::ECONNREFUSED)
      # rubocop:enable RSpec/AnyInstance

      expect { described_class.new.deliver(subscriber: subscriber, note: note) }
        .to raise_error(Deliveries::TransientError, /ECONNREFUSED/)
    end
  end

  describe Deliveries::Channels::Log do
    it 'logs the note and returns a reference' do
      allow(Rails.logger).to receive(:info)

      reference = described_class.new.deliver(subscriber: create(:subscriber), note: create(:message))

      expect(reference).to start_with('log-')
      expect(Rails.logger).to have_received(:info).with(/channel=log/)
    end
  end
end
