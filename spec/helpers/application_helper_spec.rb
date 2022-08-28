require 'rails_helper'

RSpec.describe ApplicationHelper do
  describe '#masked_email' do
    it 'keeps the first character and the domain' do
      expect(helper.masked_email('robin@example.com')).to eq('r****@example.com')
    end

    it 'does not reveal how long the local part is' do
      expect(helper.masked_email('a@example.com')).to eq('a****@example.com')
      expect(helper.masked_email('alexandra.long@example.com')).to eq('a****@example.com')
    end

    it 'returns anything that is not an address unchanged' do
      expect(helper.masked_email('nobody')).to eq('nobody')
    end
  end
end
