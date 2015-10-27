require 'spec_helper'

describe Crepe::Params do
  subject(:params) { Crepe::Params.new input }
  let(:input) { {} }

  describe '#require' do
    context 'with a present key' do
      it 'returns its value' do
        input[:key] = {'hello'=>'world'}
        expect(params.require :key).to eq(input[:key])
      end
    end

    context 'with a missing key' do
      subject { params.require :missing }

      it { expect { subject }.to raise_error(Crepe::Params::Missing) }
    end
  end

  describe '#permit' do
    context 'with secure keys' do
      let(:input) { { secure_key: 1 } }
      let(:permitted) { params.permit :secure_key }

      it { expect(permitted).to be_permitted }

      it 'permits post-dup' do
        expect(permitted.dup).to be_permitted
      end

      it 'returns itself' do
        expect(permitted).to eq params
      end
    end

    context 'with an insecure key' do
      let(:input) { { permitted: 1 } }
      subject { params.permit :invalid }

      it { expect(params).not_to be_permitted }
      it { expect { subject }.to raise_error(Crepe::Params::Invalid) }
    end
  end

  it { is_expected.to respond_to :permitted? }
end
