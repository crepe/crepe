require 'ostruct'
require_relative '../../../../lib/crepe/endpoint/acceptance'

describe Crepe::Endpoint::Acceptance do
  subject { Crepe::Endpoint::Acceptance }
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
