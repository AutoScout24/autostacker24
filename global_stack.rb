
require_relative 'stacker.rb'

class GlobalStack

  def initialize(name, options = {})
    @name = name
    @version = options[:version] || ENV['VERSION'] || ENV['GO_PIPELINE_LABEL'] || 3
    @sandbox = options[:sandbox] || ENV['SANDBOX'] || (ENV['GO_JOB_NAME'].nil? && `whoami`.strip) # use whoami if no sandbox is given
    @stack_name = Stacker.sandboxed_stack_name(@sandbox, 'global')
  end

  attr_reader :name, :sandbox, :version, :stack_name

  def outputs
    @lazy_outputs ||= Stacker.get_stack_outputs(stack_name)
  end

  def create
    Stacker.create_stack(stack_name, template, {})
  end

  def update
    Stacker.update_stack(stack_name, template, {})
  end

  def create_or_update
    Stacker.create_or_update_stack(stack_name, template, {})
  end

  def delete
     Stacker.delete_stack(stack_name)
  end

  def template
    # TODO: How to get the current version used on live?
    s3 = Aws::S3::Client.new
    s3.get_object(bucket: 'as24.tatsu.artefacts', key: "global-stack-template/#{version}/infra-vpc.json").body.read
  end
end
