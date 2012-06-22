require 'spec_helper'
require_relative '../../../../lib/cape/middleware/restful_status'

describe Cape::Middleware::RestfulStatus do

  describes_middleware

  subject { last_response.status } # Status.
  before { send method.downcase, '/' }

  context 'successful' do
    let(:status) { 200 }
    context 'POST' do
      let(:method) { 'POST' }
      it { should eq 201 }
    end

    context 'DELETE' do
      let(:method) { 'DELETE' }
      it { should eq 204 }

      context 'body' do
        subject { last_response.body }
        it { should be_empty }
      end
    end

    %w(HEAD GET PUT PATCH).each do |m|
      context m do
        let(:method) { m }
        it { should eq status }
      end
    end
  end

  context 'unsuccessful' do
    let(:status) { 403 }
    %w[POST DELETE HEAD GET PUT PATCH].each do |method|
      context method do
        let(:method) { method }
        it { should eq(status) }

        if method == 'DELETE'
          context 'body' do
            subject { last_response.body }
            it { should_not be_empty }
          end
        end
      end
    end
  end
end
