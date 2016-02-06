
require 'json'

module AutoStacker24

  module Preprocessor

    def self.preprocess(template, tags = nil)
      if template =~ /^\s*\/{2}\s*/i
        processed = preprocess_json(parse_json(template))
        template = preprocess_tags(processed, tags).to_json
      end
      template
    end

    def self.parse_json(template)
      template = template.gsub(/(\s*\/\/.*$)|(".*")/) {|m| m[0] == '"' ? m : ''} # replace comments
      JSON(template)
    rescue JSON::ParserError => e
      require 'json/pure' # pure ruby parser has better error diagnostics
      JSON(template)
      raise e
    end

    def self.preprocess_tags(template, tags = nil)

      supportedTypes = [
        'AWS::AutoScaling::AutoScalingGroup',
        'AWS::CloudTrail::Trail',
        'AWS::EC2::CustomerGateway',
        'AWS::EC2::DHCPOptions',
        'AWS::EC2::Instance',
        'AWS::EC2::InternetGateway',
        'AWS::EC2::NetworkAcl',
        'AWS::EC2::NetworkInterface',
        'AWS::EC2::RouteTable',
        'AWS::EC2::SecurityGroup',
        'AWS::EC2::Subnet',
        'AWS::EC2::Volume',
        'AWS::EC2::VPC',
        'AWS::EC2::VPCPeeringConnection',
        'AWS::EC2::VPNConnection',
        'AWS::EC2::VPNGateway',
        'AWS::ElasticBeanstalk::Environment',
        'AWS::ElasticLoadBalancing::LoadBalancer',
        'AWS::RDS::DBCluster',
        'AWS::RDS::DBClusterParameterGroup',
        'AWS::RDS::DBInstance',
        'AWS::RDS::DBParameterGroup',
        'AWS::RDS::DBSecurityGroup',
        'AWS::RDS::DBSubnetGroup',
        'AWS::RDS::OptionGroup',
        'AWS::S3::Bucket'
      ]

      unless tags.nil?

        tags_for_asg = adjust_tags_for_asg(tags)

        template["Resources"].each {|(key, value)|

          tags_to_apply = tags
          if value["Type"] == 'AWS::AutoScaling::AutoScalingGroup'
            tags_to_apply = tags_for_asg
          end

          if supportedTypes.include? value["Type"]
            if value["Properties"]["Tags"].nil?
              value["Properties"]["Tags"] = tags_to_apply
            else
              value["Properties"]["Tags"] = (tags_to_apply + value["Properties"]["Tags"]).uniq { |s| s.first }
            end
          end
        }
      end

      template
    end

    def self.adjust_tags_for_asg(tags)
      asg_tags = tags.inject([]) { |t,element| t << element.dup }

      asg_tags.each {|(tag)|
        tag["PropagateAtLaunch"] = "true"
      }

      asg_tags
    end

    def self.preprocess_json(json)
      if json.is_a?(Hash)
        json.inject({}){|m, (k, v)| m.merge(k => preprocess_json(v))}
      elsif json.is_a?(Array)
        json.map{|v| preprocess_json(v)}
      elsif json.is_a?(String)
        preprocess_string(json)
      else
        json
      end
    end

    def self.preprocess_string(s)
      parts = tokenize(s).map do |token|
        case token
          when '@@' then '@'
          when /^@/ then {'Ref' => token[1..-1]}
          else token
        end
      end

      # merge neighboured strings
      parts = parts.reduce([])do |m, p|
        if m.last.is_a?(String) && p.is_a?(String)
          m[-1] += p
        else
          m << p
        end
        m
      end

      if parts.length == 1
        parts.first
      else # we need a join construct
        {'Fn::Join' => ['', parts]}
      end
    end

    def self.tokenize(s)
      pattern = /@@|@((\w+(::)?\w+)+)/
      tokens = []
      loop do
        m = pattern.match(s)
        if m
          tokens << m.pre_match unless m.pre_match.empty?
          tokens << m.to_s
          s = m.post_match
        else
          tokens << s unless s.empty? && !tokens.empty?
          break
        end
      end
      tokens
    end

  end

end
