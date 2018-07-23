require 'aws-sdk-cloudformation'
require 'set'

require_relative 'template_preprocessor.rb'

# disable buffering to stdout and stderr so we get immediate feedback if run by Jenkins/TeamCity/Docker
STDOUT.sync = true
STDERR.sync = true

DEFAULT_TIMEOUT = 60

module Stacker

  attr_reader :region, :credentials

  # use ENV['AWS_ACCESS_KEY_ID'] and ENV['AWS_SECRET_ACCESS_KEY'] if you don't want to set credentials by code
  def credentials=(credentials)
    unless credentials == @credentials
      @lazy_cloud_formation = nil
      @credentials = credentials
    end
  end

  def region=(region) # use ENV['AWS_REGION'] or ENV['AWS_DEFAULT_REGION']
    unless region == @region
      @lazy_cloud_formation = nil
      @region = region
    end
  end

  # set custom cloudformation parameters
  def cloud_formation_params=(params)
    unless params == @cloud_formation_params
      @lazy_cloud_formation = nil
      @cloud_formation_params = params
    end
  end

  def create_or_update_stack(stack_name, template, parameters, parent_stack_name = nil, role_arn = nil, tags = nil, timeout_in_minutes = DEFAULT_TIMEOUT)
    if find_stack(stack_name).nil?
      create_stack(stack_name, template, parameters, parent_stack_name, role_arn, tags, timeout_in_minutes)
    else
      update_stack(stack_name, template, parameters, parent_stack_name, role_arn, tags, timeout_in_minutes)
    end
  end

  def create_stack(stack_name, template, parameters, parent_stack_name = nil, role_arn = nil, tags = nil, timeout_in_minutes = DEFAULT_TIMEOUT)
    merge_and_validate(template, parameters, parent_stack_name)
    cloud_formation.create_stack(stack_name:    stack_name,
                                 template_body: template_body(template),
                                 on_failure:    'DELETE',
                                 parameters:    transform_params(parameters),
                                 capabilities:  ['CAPABILITY_IAM', 'CAPABILITY_NAMED_IAM'],
                                 role_arn:      role_arn,
                                 tags:          transform_tags(tags))
    wait_for_stack(stack_name, :create, Set.new, timeout_in_minutes)
  end

  def update_stack(stack_name, template, parameters, parent_stack_name = nil, role_arn = nil, tags = nil, timeout_in_minutes = DEFAULT_TIMEOUT)
    seen_events = get_stack_events(stack_name).map {|e| e[:event_id]}
    begin
      merge_and_validate(template, parameters, parent_stack_name)
      cloud_formation.update_stack(stack_name:    stack_name,
                                   template_body: template_body(template),
                                   parameters:    transform_params(parameters),
                                   capabilities:  ['CAPABILITY_IAM', 'CAPABILITY_NAMED_IAM'],
                                   role_arn:      role_arn,
                                   tags:          transform_tags(tags))
    rescue Aws::CloudFormation::Errors::ValidationError => error
      raise error unless error.message =~ /No updates are to be performed/i # may be flaky, do more research in API
      puts "stack #{stack_name} is already up to date"
      find_stack(stack_name)
    else
      wait_for_stack(stack_name, :update, seen_events, timeout_in_minutes)
    end
  end

  def list_stacks()
    next_token = nil
    loop do
      res = cloud_formation.list_stacks(next_token: next_token)
      res.stack_summaries.each { |summary| print_stack_summary(summary) }

      next_token = res.next_token
      break if next_token.nil?
    end
  end

  def print_stack_summary(summary)
    change_date = summary.last_updated_time ? summary.last_updated_time : summary.creation_time
    puts "#{summary.stack_name}\t#{summary.stack_status}\t#{change_date}" unless summary.stack_status == 'DELETE_COMPLETE'
  end

  # if stack_name is given assign read the output parameters and copy them to the given template parameters
  # if a aparameter is already defined, it will not be overwritten
  # finally, if mandatory parameters are missing, an error will be raised
  def merge_and_validate(template, parameters, stack_name)
    valid = validate_template(template).parameters
    if stack_name
      present = valid.map{|p| p.parameter_key.to_sym}
      get_stack_output(stack_name).each do |key, value|
        parameters[key] ||= value if present.include?(key)
      end
    end
    mandatory = valid.select{|p| p.default_value.nil?}.map{|p| p.parameter_key.to_sym}
    diff = mandatory.to_set - parameters.keys.to_set
    raise "Missing one ore more mandatory parameters: #{diff.to_a.join(', ')}" if diff.length > 0
    parameters
  end
  private :merge_and_validate

  def validate_template(template)
    cloud_formation.validate_template(template_body: template_body(template))
  end

  def delete_stack(stack_name, role_arn = nil, timeout_in_minutes = 60)
    seen_events = get_stack_events(stack_name).map {|e| e[:event_id]}
    cloud_formation.delete_stack(stack_name: stack_name, role_arn: role_arn)
    wait_for_stack(stack_name, :delete, seen_events, timeout_in_minutes)
  end

  def wait_for_stack(stack_name, operation, seen_events = Set.new, timeout_in_minutes = DEFAULT_TIMEOUT)
    stop_time   = Time.now + timeout_in_minutes * 60
    finished    = /(CREATE_COMPLETE|UPDATE_COMPLETE|DELETE_COMPLETE|ROLLBACK_COMPLETE|ROLLBACK_FAILED|CREATE_FAILED|DELETE_FAILED)$/
    puts "waiting for #{operation} stack #{stack_name}"
    stack_id = find_stack(stack_name)[:stack_id]

    while Time.now < stop_time
      sleep(10)
      stack = find_stack(stack_name)
      status = stack ? stack.stack_status : 'DELETE_COMPLETE'
      expected_status = case operation
                          when :create then /CREATE_COMPLETE$/
                          when :update then /UPDATE_COMPLETE$/
                          when :delete then /DELETE_COMPLETE$/
                        end
      new_events = get_stack_events(stack_id).select{|e| !seen_events.include?(e[:event_id])}.sort_by{|e| e[:timestamp]}
      new_events.each do |e|
        seen_events << e[:event_id]
        puts "#{e[:timestamp]}\t#{e[:resource_status].ljust(20)}\t#{e[:resource_type].ljust(40)}\t#{e[:logical_resource_id].ljust(30)}\t#{e[:resource_status_reason]}"
      end
      return true if status =~ expected_status
      raise "#{operation} #{stack_name} failed, current status #{status}" if status =~ finished
    end
    raise "waiting for #{operation} stack #{stack_name} timed out after #{timeout_in_minutes} minutes"
  end

  def get_template(stack_name)
    cloud_formation.get_template(stack_name: stack_name).template_body
  end

  def find_stack(stack_name)
    cloud_formation.describe_stacks(stack_name: stack_name).stacks.first
  rescue Aws::CloudFormation::Errors::ValidationError => error
    raise error unless error.message =~ /does not exist/i # may be flaky, do more research in API
    nil
  end

  def all_stack_names
    all_stacks.map{|s| s.stack_name}
  end

  def all_stacks
    cloud_formation.describe_stacks.stacks
  end

  def estimate_template_cost(template, parameters, parent_stack_name = nil)
    merge_and_validate(template, parameters, parent_stack_name)
    cloud_formation.estimate_template_cost(:template_body => template_body(template), :parameters => transform_params(parameters))
  end

  def get_stack_outputs(stack_name)
    get_stack_output(stack_name)
  end

  def get_stack_output(stack_name)
    stack = find_stack(stack_name)
    raise "stack #{stack_name} not found" unless stack
    transform_output(stack.outputs).freeze
  end

  def transform_output(output)
    output.inject({}) { |m, o| m.merge(o.output_key.to_sym => o.output_value) }
  end

  def transform_params(input)
    input.each{|k,v| raise "#{k} must not be nil" if v.nil? }
    input.inject([]) { |m, kv| m << {parameter_key: kv[0].to_s, parameter_value: kv[1].to_s} }
  end

  def transform_tags(input)
    input.each{|k,v| raise "#{k} must not be nil" if v.nil? }
    input.inject([]) { |m, kv| m << {key: kv[0].to_s, value: kv[1].to_s} }
  end

  def get_stack_resources(stack_name)
    resources = cloud_formation.describe_stack_resources(stack_name: stack_name).data.stack_resources
    resources.inject({}){|map, resource| map.merge(resource.logical_resource_id.to_sym => resource)}.freeze
  end

  def get_stack_events(stack_name_or_id)
    cloud_formation.describe_stack_events(stack_name: stack_name_or_id).data.stack_events
  end

  def cloud_formation # lazy CloudFormation client
    unless @lazy_cloud_formation
      params = @cloud_formation_params || {}
      params[:credentials] = @credentials if @credentials
      params[:region] = @region if @region
      parmas[:retry_limit] = 10
      @lazy_cloud_formation = Aws::CloudFormation::Client.new(params)
    end
    @lazy_cloud_formation
  end

  def template_body(template)
    wd = Dir.getwd()
    if File.exists?(template) # template is a valid filename
      td = File.dirname(template)
      template = File.read(template)
      Dir.chdir(td)
    end
    AutoStacker24::Preprocessor.preprocess(template)
  ensure
    Dir.chdir(wd)
  end

  extend self

end
