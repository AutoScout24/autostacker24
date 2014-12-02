require 'yaml'
require 'aws-sdk'

module Stacker

  class CloudStack

    def initialize(options)
      @options = options
      credentials = Aws::Credentials.new(options['access_key_id'], options['secret_access_key'])
      @cf_client = Aws::CloudFormation::Client.new(
          region: options['region'],
          credentials: credentials
      )
    end

    def build(stack_name, environment_tag, template_file)
      @cf_client.create_stack(
        stack_name: stack_name,
        template_body: File.read(template_file),
          parameters: [cloudformation_parameters],
          timeout_in_minutes: 1,
          # on_failure: "DELETE",
          # stack_policy_body: "StackPolicyBody",
          # stack_policy_url: "StackPolicyURL",
          tags: [
          {
              key: "Environment",
              value: environment_tag
          }
      ])
    end

    def cloudformation_parameters()
      {}
    end

    def delete(stack_name)
      @connection.delete_stack(stack_name)
    end

  end
end

