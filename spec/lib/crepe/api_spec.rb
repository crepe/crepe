require 'spec_helper'
require 'crepe'

describe Crepe::API do

  describe '.param' do
    app { param(:action) { get { params[:action] } } }
    it 'wraps endpoints with a param-based path component' do
      expect(get('/dig').body).to include 'dig'
    end
  end

end
