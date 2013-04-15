require 'spec_helper'

describe Crepe::Params do
  subject(:params) { Crepe::Params.new input }
  let(:input) { {} }

  describe '#require' do
    context 'with a present key' do
      it 'returns its value' do
        input[:key] = {'hello'=>'world'}
        params.require(:key).should eq(input[:key])
      end
    end

    context 'with a missing key' do
      it {
        expect { params.require :missing }.to raise_error(
          Crepe::Params::Missing
        )
      }
    end
  end

  describe '#permit' do
    context 'with secure keys' do
      let(:input) { { secure_key: 1 } }
      let(:permitted) { params.permit :secure_key }

      it { expect(permitted).to be_permitted }
      it 'returns itself' do
        permitted.should eq(params)
      end
    end

    context 'with an insecure key' do
      let(:input) { { permitted: 1 } }

      it { expect(params).to_not be_permitted }
      it {
        expect { params.permit :invalid }.to raise_error(
          Crepe::Params::Invalid
        )
      }
    end
  end

  it { should respond_to :permitted? }
  it { should be_frozen }
end
