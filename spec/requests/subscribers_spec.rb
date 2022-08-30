require 'rails_helper'

RSpec.describe Api::V1::SubscribersController, type: :controller do
  let(:default_headers) do
    {
      'Content-Type' => 'application/json',
      'Accept'       => 'application/json'
    }
  end

  let(:subscriber) { create(:subscriber) }

  context '#index' do
    it 'should return success' do
      request.headers.merge!(default_headers)

      get :index
      expect(response).to be_successful
    end
  end

  context '#show' do
    it 'should return success' do
      request.headers.merge!(default_headers)

      get :show, params: { id: subscriber.id }
      expect(response).to be_successful
    end
  end

  context '#create' do
    let(:params) {
      {
        subscriber: {
          name: 'example name',
          email: 'example@text.com',
        }
    }}

    it 'creates a subscriber and returns created' do
      request.headers.merge!(default_headers)

      expect { post :create, params: params }
        .to change { Subscriber.count }.by(1)
      expect(response).to have_http_status(:created)
    end
  end

  context '#update' do
    let(:params) {{
      subscriber: {
        id: subscriber.id,
        is_active: false
      }
    }}

    it 'toggles active state' do
      request.headers.merge!(default_headers)

      expect { patch :update, params: params.merge(id: subscriber.id) }
        .to change { subscriber.reload.is_active }.from(true)
        .to(false)
      expect(response).to be_successful
    end
  end

  context '#destroy' do
    let(:params) {
      {
        id: subscriber.id,
      }
    }

    it 'deletes the subscriber and returns no content' do
      request.headers.merge!(default_headers)

      expect { delete :destroy, params: params }
        .to change { Subscriber.count }.by(-1)
      expect(response).to have_http_status(:no_content)
    end
  end

  context '#show with invalid id' do
    it 'returns not found' do
      request.headers.merge!(default_headers)

      get :show, params: { id: -1 }
      expect(response).to have_http_status(:not_found)
    end
  end
end
