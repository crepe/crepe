require 'spec_helper'

describe Crepe::API, 'versioning' do
  describe 'nesting' do
    context 'with a namespace' do
      app do
        scope :api do
          version :v1
        end
      end

      it 'raises an exception' do
        expect { app }.to raise_error ArgumentError
      end
    end

    context 'with a mount' do
      app do
        scope :api do
          v1 = Class.new Crepe::API do
            version :v1 do
              get do
                version
              end
            end
          end
          mount v1
        end
      end

      it 'routes with prefix' do
        get('/api/v1').should be_ok
        last_response.body.should include 'v1'
      end
    end
  end
end
