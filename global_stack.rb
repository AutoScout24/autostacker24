
require_relative 'Stacker.rb'

module GlobalStack

  class << self
    attr_accessor :sandbox, :version
  end

  def self.stack_name
    (sandbox ? "#{sandbox}-" : '') + name
  end

  def self.name
    'global'
  end

  def self.sandbox
    @sandbox ||= GLOBAL_SANDBOX
  end

  def self.version
    @version ||= GLOBAL_VERSION || 3
    # TODO: find current version from prod. maybe a tag in s3 must be updated, or you have to search in s3
  end

  def self.outputs
    @lazy_outputs ||= Stacker.get_stack_outputs(stack_name)
  end

  def self.create
    Stacker.create_stack(stack_name, template, {})
  end

  def self.update
    Stacker.update_stack(stack_name, template, {})
  end

  def self.create_or_update
    Stacker.create_or_update_stack(stack_name, template, {})
  end

  def self.delete
     Stacker.delete_stack(stack_name)
  end

  def self.template
    # TODO: How to get the current version used on live?
    s3 = Aws::S3::Client.new
    s3.get_object(bucket: 'as24.tatsu.artefacts', key: "global-stack-template/#{version}/infra-vpc.json").body.read
  end
end
