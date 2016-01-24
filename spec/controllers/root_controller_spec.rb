require 'rails_helper'

RSpec.describe RootController, type: :controller do
  describe '#index' do
    it 'returns a 200 ok' do
      response = get :index

      expect(response.code).to eq("200")
    end
  end
end
