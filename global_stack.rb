require_relative 'stacker.rb'

class GlobalStack

  def initialize(options = {})
    @name = 'global'
    @template = options[:template] if options.has_key?(:template)

    #@bastion_ami should be given via parameters in create_or_update, template could be overwritten directly
    # if you knew everything at construction time you could pass parameters into the constructor, but then
    # GlobalStack behaves differently than ServiceStack, but maybe this is OK

    # gstack = GlobalStack.new
    # ....
    # gstack.template = IO.read('../global-stack/global-stack.json')
    # gstack.create_or_update(:BastionAmi => File.exists?('ami.txt') ? IO.read('ami.txt') : 'ami-28b7045f')
    #

    @version = options[:version] || ENV['GLOBAL_VERSION'] || ENV['GO_PIPELINE_LABEL'] || latest_version
    @sandbox = options[:sandbox] || ENV['GLOBAL_SANDBOX'] || (ENV['GO_JOB_NAME'].nil? && `whoami`.strip) # use whoami if no sandbox is given
    @stack_name = Stacker.sandboxed_stack_name(@sandbox, @name)
  end

  attr_reader :name, :sandbox, :version, :stack_name
  attr_writer :template

  def create_or_update(parameters = {})

    # if :bastion_ami not given fetch it from s3 "global-stack-template/#{version}/ami.txt"
    unless parameters.has_key?(:BastionAmi)
      s3_key = "global-stack-template/#{version}/ami.txt"
      puts "Fetching BastionAmi from #{s3_key}"
      parameters[:BastionAmi] = s3.get_object(bucket: 'as24.tatsu.artefacts', key: s3_key).body.read.strip
    end

    Stacker.create_or_update_stack(stack_name, template, parameters)
  end

  def delete
     Stacker.delete_stack(stack_name)
  end

  def template # if not set from the outside, fetch it from s3
    if @template.nil?
      s3_key = "global-stack-template/#{version}/global-stack.json"
      puts "Fetching global stack template from #{s3_key}"
      s3.get_object(bucket: 'as24.tatsu.artefacts', key: s3_key).body.read
    else
      @template
    end
  end

  def latest_version(account_name = 'as24prod')
    s3.get_object(bucket: 'as24.tatsu.artefacts', key: "global-stack-template/current-#{account_name}.txt").body.read

    # alternatively, could we go to the stack and ask it for its "Version" parameter
  end

  def outputs
    @lazy_outputs ||= Stacker.get_stack_outputs(stack_name)
  end

  def s3
    @lazy_s3 ||= Aws::S3::Client.new
  end

end

if $0 ==__FILE__ # placeholder for interactive testing
  gstack = GlobalStack.new
end