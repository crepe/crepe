require 'spec_helper'
require_relative '../../../../lib/cape/middleware/pagination'

describe Cape::Middleware::Pagination do

  describes_middleware

  context 'paging content' do
    let(:body) { double paginate: 'paged', count: 0 }

    it 'sets the Count header' do
      get '/'
      last_response.headers['Count'].should eq('0')
    end

    it 'paginates' do
      get '/'
      last_response.body.should eq('paged')
    end

    context 'with parameters' do
      it 'sends the paging parameters' do
        body.should_receive(:paginate).with 'page'=>'2', 'per_page'=>'4'
        get '/?page=2&per_page=4&q=test'
      end
    end
  end

  context 'non-paging content' do
    let(:body) { 'unpaged' }

    it 'passes through' do
      get '/'
      last_response.headers.should_not have_key('Count')
      last_response.body.should eq('unpaged')
    end
  end
end
