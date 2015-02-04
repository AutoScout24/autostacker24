
require 'json'

module AutoStacker24

  module Preprocessor

    def self.preprocess(template)
      if template =~ /^\s*\/{2}\s*/i
        template = template.gsub(/(\s*\/\/.*$)|(".*")/) {|m| m[0] == '"' ? m : ''} # replace comments
        template = preprocess_json(JSON(template)).to_json
      end
      template
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
      pattern = /@@|@([\w:]+)/
      tokens = []
      loop do
        m = pattern.match(s)
        if m
          tokens << m.pre_match unless m.pre_match.empty?
          tokens << m.to_s
          s = m.post_match
        else
          tokens << s
          break
        end
      end
      tokens
    end

  end

end
