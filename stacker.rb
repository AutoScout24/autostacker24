#fail 'need Ruby2.0 or newer' unless RUBY_VERSION.split[0].to_i >= 2

require 'aws-sdk'

# Overridable parameters
SERVICE_VERSION = ENV['SERVICE_VERSION'] || ENV['GO_PIPELINE_LABEL']
SERVICE_SANDBOX = ENV['SERVICE_SANDBOX'] || (ENV['GO_JOB_NAME'].nil? && `whoami`.strip)
GLOBAL_VERSION  = ENV['GLOBAL_VERSION']
GLOBAL_SANDBOX  = ENV['GLOBAL_SANDBOX']


module Stacker

  def self.create_or_update_stack(stack_name, template_body, parameters)
    if find_stack(stack_name).nil?
      create_stack(stack_name, template_body, parameters)
    else
      update_stack(stack_name, template_body, parameters)
    end
  end

  def self.create_stack(stack_name, template_body, parameters)
    cloud_formation.create_stack(stack_name:    stack_name,
                                 template_body: template_body,
                                 on_failure:    'DELETE',
                                 parameters:    transform_parameters(parameters),
                                 capabilities:  ['CAPABILITY_IAM'])
    wait_for_stack(stack_name, :create)
  end

  def self.update_stack(stack_name, template_body, parameters)
    begin
      cloud_formation.update_stack(stack_name:    stack_name,
                                   template_body: template_body,
                                   parameters:    transform_parameters(parameters),
                                   capabilities:  ['CAPABILITY_IAM'])
    rescue Aws::CloudFormation::Errors::ValidationError => error
      raise error unless error.message =~ /No updates are to be performed/i # may be flaky, do more research in API
    end
    wait_for_stack(stack_name, :update)
  end

  def self.delete_stack(stack_name)
    cloud_formation.delete_stack(stack_name: stack_name)
    wait_for_stack(stack_name, :delete)
  end

  def self.wait_for_stack(stack_name, operation, timeout_in_minutes = 15)
    stop_time = Time.now + timeout_in_minutes * 60
    finished = /(CREATE_COMPLETE|UPDATE_COMPLETE|DELETE_COMPLETE|ROLLBACK_COMPLETE|ROLLBACK_FAILED|CREATE_FAILED)$/
    while Time.now < stop_time
      stack = find_stack(stack_name)
      status = stack ? stack.stack_status : 'DELETE_COMPLETE'
      puts "waiting for stack #{stack_name}, current status #{status}"
      expected_status = case operation
                          when :create then /CREATE_COMPLETE/
                          when :update then /CREATE_COMPLETE|UPDATE_COMPLETE/
                          when :delete then /DELETE_COMPLETE/
                        end
      return true if status =~ expected_status
      fail "waiting for stack #{stack_name} failed, current status #{status}" if status =~ finished
      sleep(5)
    end
    fail "waiting for stack timeout after #{timeout_in_minutes} minutes"
  end

  def self.find_stack(stack_name)
    cloud_formation.describe_stacks(stack_name: stack_name).stacks.first
  rescue Aws::CloudFormation::Errors::ValidationError => error
    raise error unless error.message =~ /does not exist/i # may be flaky, do more research in API
    nil
  end

  def self.get_stack_outputs(stack_name, hash = {})
    transform_outputs(find_stack(stack_name).outputs, hash)
  end

  def self.transform_outputs(outputs, hash = {})
    outputs.inject(hash) { |m, o| m.merge(o.output_key.to_sym => o.output_value) }
  end

  def self.transform_parameters(hash)
    hash.inject([]) { |m, kv| m << {parameter_key: kv[0].to_s, parameter_value: kv[1].to_s} }
  end

  def self.cloud_formation # lazy CloudFormation client
    @lazy_cloud_formation ||= Aws::CloudFormation::Client.new
  end

end

if $0 ==__FILE__ # placeholder for interactive testing
  puts "Started"
  puts GlobalStack.outputs
  puts "Done"
end
