require 'spec_helper'
require 'crepe'

describe Crepe::API do
  describe '.use' do
    let(:app) {
      Class.new described_class do
        middleware = Class.new do
          def initialize app, *args, &block
            @app, @args, @block = app, args, block
          end

          def call env
            [200, {}, [[*@args, *@block.call]]]
          end
        end

        use middleware, 1, 2, 3 do
          4
        end
      end
    }

    it 'accepts middleware, args, and block' do
      get '/'
      last_response.body.should eq '[1, 2, 3, 4]'
    end
  end
end
