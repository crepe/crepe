require 'spec_helper'

describe Crepe::Endpoint, 'acceptance' do
  app do
    respond_to :json

    get do
      { hello: 'world' }
    end
  end

  context 'unacceptable content' do
    it 'renders Not Acceptable' do
      expect(get('/.xml').body).to eq JSON.dump(
        error: { message: 'Not Acceptable', accepts: ['application/json'] }
      )
    end
  end
end
