require 'rails_helper'

RSpec.describe Api::V1::MessagesController, type: :controller do
  let(:default_headers) do
    {
      'Content-Type' => 'application/json',
      'Accept'       => 'application/json'
    }
  end

  let(:message) { create(:message) }

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

      get :show, params: { id: message.id }
      expect(response).to be_successful
    end
  end

  context '#create' do
    let(:params) {
      {
        message: {
          text: 'example text',
        }
    }}

    it 'creates a message and returns created' do
      request.headers.merge!(default_headers)

      expect { post :create, params: params }
        .to change { Message.count }.by(1)
      expect(response).to have_http_status(:created)
    end
  end

  context '#update' do
  let(:message_1) { create(:message, text: 'text') }

    let(:params) {{
      message: {
        text: 'new text'
      }
    }}

    it 'updates the message text' do
      request.headers.merge!(default_headers)

      expect { patch :update, params: params.merge(id: message_1.id) }
        .to change { message_1.reload.text }.from('text')
        .to('new text')
      expect(response).to be_successful
    end
  end

  context '#destroy' do
    let(:params) {
      {
        id: message.id,
      }
    }

    it 'deletes the message and returns no content' do
      request.headers.merge!(default_headers)

      expect { delete :destroy, params: params }
        .to change { Message.count }.by(-1)
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
