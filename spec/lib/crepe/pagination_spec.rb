require_relative '../../../../lib/crepe/endpoint/pagination'
require 'active_support/core_ext/hash/slice'
require 'ostruct'

describe Crepe::Endpoint::Pagination do
  subject { Crepe::Endpoint::Pagination }
  let(:endpoint) { OpenStruct.new body: body, headers: {}, params: params }
  let(:params) { {} }

  context 'paging content' do
    let(:body) { double paginate: 'Paged response', count: 0 }

    it 'sets the Count header' do
      subject.filter endpoint
      endpoint.headers['Count'].should eq('0')
    end

    it 'paginates' do
      subject.filter endpoint
      endpoint.body.should eq('Paged response')
    end

    context 'with parameters' do
      let(:params) { { page: 2, per_page: 4, q: 'query' } }

      it 'sends the paging parameters' do
        body.should_receive(:paginate).with page: 2, per_page: 4
        subject.filter endpoint
      end
    end
  end

  context 'non-paging content' do
    let(:body) { 'Unpaging response' }

    it 'passes through' do
      subject.filter endpoint
      endpoint.headers.should_not have_key('Count')
      endpoint.body.should eq('Unpaging response')
    end
  end
end
