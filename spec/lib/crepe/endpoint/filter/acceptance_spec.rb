require 'ostruct'
require_relative '../../../../../lib/crepe/endpoint/filter/acceptance'

describe Crepe::Endpoint::Filter::Acceptance do
  subject { Crepe::Endpoint::Filter::Acceptance }
  let(:endpoint) {
    # FIXME: Test an actual endpoint?
    OpenStruct.new config: { formats: %w[json] }, format: :pdf
  }

  context 'unacceptable content' do
    it 'renders Not Acceptable' do
      endpoint.should_receive(:error!).with(:not_acceptable)
      subject.filter endpoint
    end
  end
end
