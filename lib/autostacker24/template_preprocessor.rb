
require 'json'
require 'set'

module AutoStacker24

  module Preprocessor

    def self.preprocess(template)
      if template =~ /^\s*\/{2}\s*/i
        template = preprocess_json(parse_json(template)).to_json
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

    def self.preprocess_json(json)
      if json.is_a?(Hash)
        json.inject({}) do |m, (k, v)|
          if k == 'UserData' && v.is_a?(String)
            m.merge(k => preprocess_user_data(v))
          else
            m.merge(k => preprocess_json(v))
          end
        end
      elsif json.is_a?(Array)
        json.map{|v| preprocess_json(v)}
      elsif json.is_a?(String)
        preprocess_string(json)
      else
        json
      end
    end

    def self.preprocess_user_data(s)
      m = /^@file:\/\/(.*)/.match(s)
      s = File.read(m[1]) if m
      {'Fn::Base64' => s}
    end

    def self.preprocess_string(s)
      parts = tokenize(s).map do |token|
        case token
          when '@@' then '@'
          when '@[' then '['
          when /^@/ then parse_ref(token)
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

    def self.parse_ref(token)
      m = /^@([^\[]*)(\[([^,]*)(\s*,\s*(.*))?\])?$/.match(token)
      m1 = m[1]
      m2 = m[3]
      m3 = m[5]
      if m2
        args = if m3
                  [m1, m2, m3]
               else
                 [m1 + 'Map', '@' + m1, m2]
               end
        {'Fn::FindInMap' => [args[0], preprocess_string(args[1]), preprocess_string(args[2])]}
      else
        {'Ref' => m1}
      end
    end

    def self.tokenize(s)
      # for recursive bracket matching see
      # http://stackoverflow.com/questions/19486686/recursive-nested-matching-pairs-of-curly-braces-in-ruby-regex
      # but for we limit ourself to one level to make things less complex
      pattern = /@@|@\[|@(\w+(::\w+)?)(\[[^\]]*\])?/
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
