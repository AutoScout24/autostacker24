require 'spec_helper'

RSpec.describe 'Interpolate' do

  def interpolate(s)
    # AutoStacker24::Preprocessor.preprocess_string(s)
    AutoStacker24::Preprocessor.interpolate(s)
  end

  it 'can handle empty strings' do
    expect(interpolate('')).to eq('')
  end

  it 'does not interpolate strings without AT' do
    expect(interpolate('hullebulle')).to eq('hullebulle')
  end

  it 'does not interpolate []' do
    expect(interpolate('hullebulle[bla]')).to eq('hullebulle[bla]')
  end

  it 'does not interpolate ::' do
    expect(interpolate('hullebulle::bla')).to eq('hullebulle::bla')
  end

  it 'does not interpolate .' do
    expect(interpolate('hullebulle.bla')).to eq('hullebulle.bla')
  end

  it 'escapes AT' do
    expect(interpolate('hullebulle@@bla.com')).to eq('hullebulle@bla.com')
  end

  # it 'replaces Param' do
  #   expect(interpolate('@Param')).to eq({'Ref' => 'Param'})
  # end
  #
  # it 'replaces AWS::Param' do
  #   expect(interpolate('@AWS::Param')).to eq({'Ref' => 'AWS::Param'})
  # end
  #
  # it 'stops interpolatiog at AT' do
  #   #expect(interpolate('@AWS::Param')).to eq({'Ref' => 'AWS::Param'})
  # end

end