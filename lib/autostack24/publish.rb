require 'aws-sdk'

module Stacker

  def self.publish_global_stack_template(template_contents, global_template_version)
    s3client.put_object(bucket: 'as24.tatsu.artefacts', 
        key: "global-stack-template/#{global_template_version}/global-stack.json", 
        body: template_contents)
  end

  def self.publish_global_ami(ami_id, global_template_version)
    s3client.put_object(
      bucket: 'as24.tatsu.artefacts', 
      key: "global-stack-template/#{global_template_version}/ami.txt", 
      body: ami_id
    )
  end

  def self.publish_global_template_version(account_name, global_template_version)
    s3client.put_object(
      bucket: 'as24.tatsu.artefacts',
      key: "global-stack-template/current-#{account_name}.txt", 
      body: global_template_version,
      acl: "bucket-owner-full-control"
    )
  end

  def self.s3client
    Aws::S3::Client.new(:region => ENV['AWS_DEFAULT_REGION'] || 'eu-west-1')
  end

end
