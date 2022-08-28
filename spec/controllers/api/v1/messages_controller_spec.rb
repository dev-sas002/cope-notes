require 'rails_helper'

RSpec.describe Api::V1::MessagesController, type: :controller do
  let(:default_headers) do
    {
      'Content-Type' => 'application/json',
      'Accept' => 'application/json'
    }
  end

  let(:message) { create(:message) }

  describe '#index' do
    it 'returns success' do
      request.headers.merge!(default_headers)

      get :index
      expect(response).to be_successful
    end
  end

  describe '#show' do
    it 'returns success' do
      request.headers.merge!(default_headers)

      get :show, params: { id: message.id }
      expect(response).to be_successful
    end
  end

  describe '#create' do
    let(:params) do
      {
        message: {
          text: 'example text'
        }
      }
    end

    it 'creates a message and returns created' do
      request.headers.merge!(default_headers)

      expect { post :create, params: params }
        .to change { Message.count }.by(1)
      expect(response).to have_http_status(:created)
    end
  end

  describe '#update' do
    let(:existing_message) { create(:message, text: 'text') }

    let(:params) do
      {
        message: {
          text: 'new text'
        }
      }
    end

    it 'updates the message text' do
      request.headers.merge!(default_headers)

      expect { patch :update, params: params.merge(id: existing_message.id) }
        .to change { existing_message.reload.text }.from('text')
        .to('new text')
      expect(response).to be_successful
    end
  end

  describe '#destroy' do
    let!(:existing_message) { create(:message) }

    it 'deletes the message and returns no content' do
      request.headers.merge!(default_headers)

      expect { delete :destroy, params: { id: existing_message.id } }
        .to change { Message.count }.by(-1)
      expect(response).to have_http_status(:no_content)
    end
  end

  describe '#show with invalid id' do
    it 'returns not found' do
      request.headers.merge!(default_headers)

      get :show, params: { id: -1 }
      expect(response).to have_http_status(:not_found)
    end
  end

  describe '#index payload' do
    it 'serializes id, text and the subscribers that received the message' do
      subscriber_email = create(:subscriber_email)
      request.headers.merge!(default_headers)

      get :index
      body = response.parsed_body

      expect(body.first.keys).to contain_exactly('id', 'text', 'review_status', 'deliveries_count', 'subscribers')
      expect(body.first['subscribers'].first['id']).to eq(subscriber_email.subscriber_id)
    end
  end

  describe '#create with invalid params' do
    it 'returns unprocessable entity for a blank text' do
      request.headers.merge!(default_headers)

      expect { post :create, params: { message: { text: '' } } }
        .not_to change { Message.count }
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body).to have_key('text')
    end

    it 'returns unprocessable entity for text over the length limit' do
      request.headers.merge!(default_headers)

      post :create, params: { message: { text: 'a' * 501 } }
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'returns bad request when the message key is missing' do
      request.headers.merge!(default_headers)

      post :create, params: {}
      expect(response).to have_http_status(:bad_request)
      expect(response.parsed_body).to have_key('error')
    end
  end

  describe '#create screening' do
    it 'stores a harmful note as rejected so it can never be selected' do
      request.headers.merge!(default_headers)

      post :create, params: { message: { text: 'You should just end it all.' } }

      expect(response).to have_http_status(:created)
      expect(response.parsed_body['review_status']).to eq(Message::REJECTED)
      expect(Message.deliverable).to be_empty
    end

    it 'approves an ordinary note' do
      request.headers.merge!(default_headers)

      post :create, params: { message: { text: 'There is hope.' } }

      expect(response.parsed_body['review_status']).to eq(Message::APPROVED)
    end
  end

  describe '#index filtered by review status' do
    it 'returns only the notes an editor needs to look at' do
      flagged = create(:message, :flagged)
      create(:message)
      request.headers.merge!(default_headers)

      get :index, params: { review_status: Message::FLAGGED }

      expect(response.parsed_body.map { |note| note['id'] }).to eq([flagged.id])
    end

    it 'ignores an unknown review status instead of returning nothing' do
      create(:message)
      request.headers.merge!(default_headers)

      get :index, params: { review_status: 'nonsense' }

      expect(response.parsed_body.size).to eq(1)
    end
  end

  describe '#update with invalid params' do
    it 'returns unprocessable entity and leaves the record untouched' do
      request.headers.merge!(default_headers)

      expect { patch :update, params: { id: message.id, message: { text: '' } } }
        .not_to change { message.reload.text }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe '#destroy with invalid id' do
    it 'returns not found' do
      request.headers.merge!(default_headers)

      delete :destroy, params: { id: -1 }
      expect(response).to have_http_status(:not_found)
    end
  end
end
