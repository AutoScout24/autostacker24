require 'spec_helper'

RSpec.describe Stacker do
  before do
    @fake_stacks_response = {
      stacks: [
        stack_id: 'hay_stack',
        stack_name: 'baby francis',
        stack_status: 'married',
        creation_time: Time.now()
      ]
    }
    @fake_stack_deleted_response = {
      stacks: [
        stack_id: 'hay_stack',
        stack_name: 'baby francis',
        stack_status: 'DELETE_COMPLETE',
        creation_time: Time.now()
      ]
    }
    @fake_stack_events_response = {
      stack_events: [
        {
          stack_id: 'I swear its not a fake ID',
          event_id: '100',
          stack_name: 'hay_stack',
          timestamp: Time.now(),
          resource_status: 'married',
          resource_type: 'person',
          logical_resource_id: 'instance',
          resource_status_reason: 'insanity',
        },
        {
          stack_id: 'I swear its not a fake ID',
          event_id: '200',
          stack_name: 'hay_stack',
          timestamp: Time.now(),
          resource_status: 'endlessly happy',
          resource_type: 'instance',
          logical_resource_id: 'instance',
          resource_status_reason: 'insanity',
        }
      ]
    }
    @cf_client = Aws::CloudFormation::Client.new(stub_responses: true)
    allow(Aws::CloudFormation::Client).to receive(:new).and_return(@cf_client)
  end

  after(:each) do
    Stacker.instance_variable_set :@lazy_cloud_formation, nil
  end

  context 'find_stack' do
    describe 'when AWS API returns Aws::CloudFormation::Errors::Throttling "Rate Exceeded" exception' do
      it 'should back off and retry' do
        @cf_client.stub_responses(:describe_stacks,
          Aws::CloudFormation::Errors::Throttling.new("First parm", "Rate Exceeded"),
          Aws::CloudFormation::Errors::Throttling.new("First parm", "Rate Exceeded"),
          @fake_stacks_response
        )

        expect(Stacker.find_stack('hay_stack')[:stack_id]).to eq @fake_stacks_response[:stacks].first[:stack_id]
      end

      it 'should re-raise the exception after 5 throttling errors' do
        @cf_client.stub_responses(:describe_stacks,
          Aws::CloudFormation::Errors::Throttling.new("First parm", "Rate Exceeded"),
        )

        expect {Stacker.find_stack('hay_stack')}.to raise_error(Aws::CloudFormation::Errors::Throttling)
      end

      describe 'when AWS API returns a different exception' do
        it 'should re-raise the error' do
          @cf_client.stub_responses(:describe_stacks,
            ArgumentError.new("Your argument is invalid!"),
          )

          expect {Stacker.find_stack('hay_stack')}.to raise_error(ArgumentError)
        end
      end
    end
  end

  context 'wait_for_stack' do
    describe 'when AWS API returns Aws::CloudFormation::Errors::Throttling "Rate Exceeded" exception' do
      it 'should back off and retry successfully' do
        @cf_client.stub_responses(:describe_stacks, @fake_stacks_response, @fake_stack_deleted_response)
        @cf_client.stub_responses(:describe_stack_events,
          Aws::CloudFormation::Errors::Throttling.new("First parm", "Rate Exceeded"),
          Aws::CloudFormation::Errors::Throttling.new("First parm", "Rate Exceeded"),
          @fake_stack_events_response
        )

        expect(Stacker.wait_for_stack('hay_stack', :delete)).to eq true
      end

      it 'should fail after being throttled 5 times' do
        @cf_client.stub_responses(:describe_stacks, @fake_stacks_response, @fake_stack_deleted_response)
        @cf_client.stub_responses(:describe_stack_events,
          Aws::CloudFormation::Errors::Throttling.new("First parm", "Rate Exceeded"),
        )

        expect{Stacker.wait_for_stack('hay_stack', :delete)}.to raise_error(Aws::CloudFormation::Errors::Throttling)
      end
    end
  end

  context 'get_stack_events' do
    describe 'when AWS API returns Aws::CloudFormation::Errors::Throttling "Rate Exceeded" exception' do
      it 'should back off and retry' do
        @cf_client.stub_responses(:describe_stack_events,
          Aws::CloudFormation::Errors::Throttling.new("First parm", "Rate Exceeded"),
          Aws::CloudFormation::Errors::Throttling.new("First parm", "Rate Exceeded"),
          @fake_stack_events_response
        )

        expect(Stacker.get_stack_events('hay_stack').first[:stack_id]).to eq @fake_stack_events_response[:stack_events].first[:stack_id]
      end

      it 'should re-raise the exception after 5 throttling errors' do
        @cf_client.stub_responses(:describe_stack_events,
          Aws::CloudFormation::Errors::Throttling.new("First parm", "Rate Exceeded"),
        )

        expect {Stacker.get_stack_events('hay_stack')}.to raise_error(Aws::CloudFormation::Errors::Throttling)
      end

      describe 'when AWS API returns a different exception' do
        it 'should re-raise the error' do
          @cf_client.stub_responses(:describe_stack_events,
            ArgumentError.new("Your argument is invalid!"),
          )

          expect {Stacker.get_stack_events('hay_stack')}.to raise_error(ArgumentError)
        end
      end
    end
  end
end
