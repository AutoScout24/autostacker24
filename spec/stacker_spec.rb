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

  end

end
