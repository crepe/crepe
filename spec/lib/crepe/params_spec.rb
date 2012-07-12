require_relative '../../../lib/crepe/params'

describe Crepe::Params do
  subject :params

  describe '#require' do
    context 'with a present key' do
      it 'returns its value' do
        params[:key] = {}
        params.require(:key).should eq(params[:key])
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
      let(:permitted) { params.update(secure_key: 1).permit(:secure_key) }

      it { expect(permitted).to be_permitted }
      it 'returns itself' do
        permitted.should eq(params)
      end
    end

    context 'with an insecure key' do
      before { params.update permitted: 1 }

      it { expect(params).to_not be_permitted }
      it {
        expect { params.permit :invalid }.to raise_error(
          Crepe::Params::Invalid
        )
      }
    end
  end

  it { should respond_to(:permitted?) }
end
