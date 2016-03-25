require 'spec_helper'

RSpec.describe 'Interpolate' do

  def interpolate(s)
    #AutoStacker24::Preprocessor.preprocess_string(s)
    AutoStacker24::Preprocessor.interpolate(s)
  end

  def join(*args)
    {'Fn::Join' => ['', args]}
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

  it 'escapes AT everywhere' do
    expect(interpolate('@@hullebulle@@bla.com@@')).to eq('@hullebulle@bla.com@')
  end

  it 'escapes ".[:" even if not strictly necessary' do
    expect(interpolate('@.@[@: .[:')).to eq('.[: .[:')
  end

  it 'replaces Param' do
    expect(interpolate('@Param')).to eq({'Ref' => 'Param'})
  end

  it 'replaces AWS::Param' do
    expect(interpolate('@AWS::Param')).to eq({'Ref' => 'AWS::Param'})
  end

  it 'joins multiple parts' do
    expect(interpolate('bla @Param-blub')).to eq(join('bla ', {'Ref' => 'Param'}, '-blub'))
  end

  it 'expression stops at "@"' do
    expect(interpolate('@Param@::text')).to eq(join({'Ref' => 'Param'}, '::text'))
  end

  it 'dot generates Fn::GetAtt' do
    expect(interpolate('@Param.attr1.attr2')).to eq({'Fn::GetAtt' => ['Param', 'attr1.attr2']})
  end

  it 'dot generates Fn::GetAtt embedded' do
    expect(interpolate('bla @Param.attr bla')).to eq(join('bla ', {'Fn::GetAtt' => ['Param', 'attr']}, ' bla'))
  end

  it '[top,second] generates Fn::FindInMap' do
    expect(interpolate('@MyMap[Top, Second]')).to eq({'Fn::FindInMap' => ['MyMap', 'Top', 'Second']})
  end

  it '[top,second] generates Fn::FindInMap embedded' do
    expect(interpolate('@MyMap[  Top  ,Second  ]bla')).to eq(join({'Fn::FindInMap' => ['MyMap', 'Top', 'Second']}, 'bla'))
  end

  it '@Top[second] generate Fn::FindInMap by convention' do
    expect(interpolate('@My[Second]')).to eq({'Fn::FindInMap' => ['MyMap', {'Ref' => 'My'}, 'Second']})
  end
end