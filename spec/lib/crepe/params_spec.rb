require 'spec_helper'

describe Crepe::Params do
  subject(:params) { Crepe::Params.new input }
  let(:input) { {} }

  context 'with a value' do
    let(:input) { { a: 'b', c: ['d', { e: 'f', g: ['h'] } ] } }

    it 'returns a frozen value unless duped' do
      expect(params[:a]).to be_frozen
      expect(params[:c]).to be_frozen
      expect(params[:c][0]).to be_frozen
      expect(params[:c][1]).to be_frozen
      expect(params[:c][1][:e]).to be_frozen
      expect(params[:c][1][:g]).to be_frozen
      expect(params[:c][1][:g][0]).to be_frozen

      duped = params.dup
      expect(duped[:a]).to_not be_frozen
      expect(duped[:c]).to_not be_frozen
      expect(duped[:c][0]).to_not be_frozen
      expect(duped[:c][1]).to_not be_frozen
      expect(duped[:c][1][:e]).to_not be_frozen
      expect(duped[:c][1][:g]).to_not be_frozen
      expect(duped[:c][1][:g][0]).to_not be_frozen
    end
  end

  describe '#require' do
    context 'with a present key' do
      it 'returns its value' do
        input[:key] = {'hello'=>'world'}
        expect(params.require :key).to eq(input[:key])
      end
    end

    context 'with a missing key' do
      it { expect { params.require :missing }.to raise_error }
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

      it 'thaws post-dup' do
        expect(permitted.dup).to_not be_frozen
      end

      it 'returns itself' do
        expect(permitted).to eq params
      end
    end

    context 'with an insecure key' do
      let(:input) { { permitted: 1 } }

      it { expect(params).not_to be_permitted }
      it { expect { params.permit :invalid }.to raise_error }
    end
  end

  it { is_expected.to respond_to :permitted? }

  it 'freezes' do
    is_expected.to be_frozen
    expect { params[:frozen] = true }.to raise_exception
  end
end
