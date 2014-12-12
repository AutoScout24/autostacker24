require 'json'
require 'stacker/stacker.rb'

class ServiceStack

  def initialize(name, options = {})
    @name = name
    @version = options[:version] || ENV['VERSION'] || ENV['GO_PIPELINE_LABEL']
    @sandbox = options[:sandbox] || ENV['SANDBOX'] || (ENV['GO_JOB_NAME'].nil? && `whoami`.strip) # use whoami if no sandbox is given
    @global_stack_name  = options[:global_stack_name] || ENV['GLOBAL_STACK_NAME'] || 'global'
    @stack_name = Stacker.sandboxed_stack_name(@sandbox, @name)
  end

  attr_reader :name, :sandbox, :version, :stack_name, :global_stack_name

  def create_or_update(template, parameters)
    inputs = JSON(template)['Parameters']
    global_outputs.each{|k, v| parameters[k.to_sym] = v if inputs.has_key?(k.to_s)}
    parameters[:Version] = version
    Stacker.create_or_update_stack(stack_name, template, parameters)
  end

  def delete
    Stacker.delete_stack(stack_name)
  end

  def outputs
    @lazy_outputs ||= Stacker.get_stack_outputs(stack_name).freeze
  end

  def url
    "http://#{stack_name}.#{global_outputs[:AccountSubDomain]}.autoscout24.com"
  end

  def estimate(template)
    Stacker.estimate_template_cost(template)
  end

  def global_outputs
    @lazy_global_outputs ||= Stacker.get_stack_outputs(global_stack_name)
  end
end

if $0 ==__FILE__ # placeholder for interactive testing

end
