require 'spec_helper'

describe Crepe::API, '.helper' do
  app do
    scope :block do
      get do
        { name: name }
      end

      helper do
        def name
          'block'
        end
      end
    end

    scope :module do
      get do
        { name: name }
      end

      mod = Module.new do
        def name
          'module'
        end
      end
      helper mod

      scope :nest do
        get do
          { name: name, body: body }
        end

        helper do
          def name
            "#{super} and block"
          end

          def body
            "body"
          end
        end
      end
    end

    get do
      { name: name }
    end
  end

  it 'extends endpoints with block methods' do
    get('/block').body.should include 'block'
  end

  it 'extends endpoints with module methods' do
    get('/module').body.should include 'module'
  end

  it 'extends nested endpoints with outer and inner helpers' do
    get('/module/nest').body.should include 'module and block'
    get('/module/nest').body.should include 'body'
  end

  it 'does not extend outer endpoints with inner helpers' do
    get('/').body.should include "undefined local variable or method `name'"
  end
end
