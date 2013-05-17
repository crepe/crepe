require 'spec_helper'

describe Crepe::API do
  describe '.let' do
    app do
      let :once do
        @once ||= 0
        @once  += 1
      end

      helper do
        def many
          @many ||= 0
          @many  += 1
        end
      end

      get do
        { once: [once, once, once], many: [many, many, many] }
      end
    end

    it 'memoizes the return value' do
      get('/').body.should eq '{"once":[1,1,1],"many":[1,2,3]}'
    end

    context 'with block arguments' do
      app do
        let :incr do |n, amount = 1|
          n + amount
        end

        get ':n' do
          n = params[:n].to_i
          { 'n + 1' => incr(n), 'n + 2' => incr(n, 2), 'n + 3' => incr(n, 3) }
        end
      end

      it 'memoizes depending on input' do
        get('/1').body.should eq '{"n + 1":2,"n + 2":3,"n + 3":4}'
      end
    end
  end

  describe '.let!' do
    app do
      let! :current_user do
        @current_user = true
      end

      get do
        { logged_in: !defined?(@current_user).nil? }
      end
    end

    it 'invokes the helper before the handler' do
      get('/').body.should eq '{"logged_in":true}'
    end
  end
end
