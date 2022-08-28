require 'rails_helper'

RSpec.describe 'Unsubscribe links' do
  let(:subscriber) { create(:subscriber, email: 'robin@example.com', is_active: true) }

  describe 'GET /unsubscribe/:token' do
    it 'asks for confirmation without changing anything' do
      get unsubscribe_path(subscriber.unsubscribe_token)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Stop receiving notes?', 'r****@example.com')
      expect(subscriber.reload.is_active).to be(true)
    end

    it 'says so when the subscriber has already left' do
      subscriber.update!(is_active: false)

      get unsubscribe_path(subscriber.unsubscribe_token)

      expect(response.body).to include('already unsubscribed')
      expect(response.body).not_to include('<button')
    end

    it 'answers 404 with a helpful page for an unknown token' do
      get unsubscribe_path('not-a-real-token')

      expect(response).to have_http_status(:not_found)
      expect(response.body).to include('This link did not work')
    end
  end

  describe 'POST /unsubscribe/:token' do
    it 'deactivates the subscriber' do
      post unsubscribe_path(subscriber.unsubscribe_token)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('You are unsubscribed')
      expect(subscriber.reload.is_active).to be(false)
    end

    it 'accepts an RFC 8058 one-click request with no CSRF token' do
      ActionController::Base.allow_forgery_protection = true
      post unsubscribe_path(subscriber.unsubscribe_token), params: { 'List-Unsubscribe' => 'One-Click' }

      expect(response).to have_http_status(:ok)
      expect(subscriber.reload.is_active).to be(false)
    ensure
      ActionController::Base.allow_forgery_protection = false
    end

    it 'is idempotent' do
      2.times { post unsubscribe_path(subscriber.unsubscribe_token) }

      expect(response).to have_http_status(:ok)
      expect(subscriber.reload.is_active).to be(false)
    end

    it 'leaves every other subscriber alone' do
      other = create(:subscriber, is_active: true)

      post unsubscribe_path(subscriber.unsubscribe_token)

      expect(other.reload.is_active).to be(true)
    end

    it 'does nothing for an unknown token' do
      post unsubscribe_path('not-a-real-token')

      expect(response).to have_http_status(:not_found)
      expect(subscriber.reload.is_active).to be(true)
    end
  end
end
