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

      mod = Module.new do
        def name
          'module'
        end
      end
      helper mod

    end

    get do
      { name: name }
    end
  end

  it 'extends endpoints with block methods' do
    expect(get('/block').body).to include 'block'
  end

  it 'extends endpoints with module methods' do
    expect(get('/module').body).to include 'module'
  end

  it 'extends nested endpoints with outer and inner helpers' do
    expect(get('/module/nest').body).to include 'module and block'
    expect(get('/module/nest').body).to include 'body'
  end

  it 'does not extend outer endpoints with inner helpers' do
    message = "undefined local variable or method `name'"
    expect(get('/').body).to include message
  end
end
