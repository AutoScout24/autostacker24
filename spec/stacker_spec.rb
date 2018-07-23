require 'spec_helper'
require 'json'

RSpec.describe Stacker do

  describe 'template_body' do

    it 'should not change working directory if template is invalid' do
      wd = Dir.getwd()
      begin
        Stacker.template_body('./spec/examples/invalid.yaml')
      rescue
        # catch all
      end
      expect(wd).to eq(Dir.getwd())
    end

    it 'should not change working directory if template is not a filename' do
      wd = Dir.getwd()
      template =  <<-EOL
        # AutoStacker24 enabled CloudFormation template
        Parameters:
          Environment: # Some Comments
            Type: String
            Default: Staging
      EOL
      JSON.parse(Stacker.template_body(template))
      expect(wd).to eq(Dir.getwd())
    end

    it 'should include relative file if template is a filename' do
      json = JSON.parse(Stacker.template_body('./spec/examples/valid.yaml'))
      expect(json['Include']['File']).to eq("#!/usr/bin/env bash\necho \"bla\"")
    end

    it 'should transform single tags to expected format' do
      input = {'key1' => 'value1'}
      expect(Stacker.transform_tags(input)).to eq([{key: 'key1', value: 'value1'}])
    end

    it 'should transform multiple tags to expected format' do
      input = {'key1' => 'value1', 'key2' => 'value2'}
      expect(Stacker.transform_tags(input)).to eq([{key: 'key1', value: 'value1'},{key: 'key2', value: 'value2'}])
    end

    it 'should reject nil value tags' do
      input = {'key1' => nil}
      expect {Stacker.transform_tags(input)}.to raise_error(RuntimeError,'key1 must not be nil')
    end

    it 'should work with empty tags' do
      input = {}
      expect(Stacker.transform_tags(input)).to eq([])
    end
  end

end
