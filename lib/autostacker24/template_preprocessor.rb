
require 'json'
require 'set'
require 'yaml'

module AutoStacker24

  module Preprocessor

    def self.preprocess(template)
      if template =~ /\A\s*\{/
        template
      elsif template =~ /\A\s*\/{2}/
        preprocess_json(parse_json(template)).to_json
      else
        preprocess_json(parse_yaml(template)).to_json
      end
    end

    def self.parse_json(template)
      JSON(template)
    rescue JSON::ParserError => e
      require 'json/pure' # pure ruby parser has better error diagnostics
      JSON(template)
      raise e
    end

    def self.parse_yaml(template)
      YAML.load(template)
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
        interpolate(json)
      else
        json
      end
    end

    def self.preprocess_user_data(s)
      {'Fn::Base64' => interpolate(s)}
    end

    # interpolates a string with '@' expressions and returns a string or a hash
    # it implements the following non context free grammar in pseudo antlr3
    #
    # string : RAW? (expr RAW?)*;
    # expr   : '@' name (attr+ | map)?;
    # name   : ID ('::' ID)?;
    # attr   : ('.' ID)+;
    # map    : '[' key (',' key)? ']';
    # key    : ID | expr;
    # ID     : [a-zA-Z0-9]+;
    # RAW    : (~['@']* | FILE)=;
    # FILE   : '@file://' [^@\s]+ '@' | ' ';
    #
    def self.interpolate(s)
      parts = []
      while s.length > 0
        raw, s = parse_raw(s)
        parts << raw unless raw.empty?
        expr, s = parse_expr(s)
        parts << expr if expr
      end
      case parts.length
        when 0 then ''
        when 1 then parts[0]
        else {'Fn::Join' => ['', parts]}
      end
    end

    def self.parse_raw(s)
      i = 0
      loop do
        i = s.index('@', i)
        return s, '' if i.nil?

        m = /\A@file:\/\/([^@\s]+)@?/.match(s[i..-1])
        if m # inline file
          s = s[0, i] + File.read(m[1]) + m.post_match
        elsif s[i, 2] !~ /@\w/ # escape
          s = s[0, i] + s[i+1..-1]
          i += 1
        else
          return s[0, i], s[i..-1] if s[i, 2]
        end
      end
    end

    def self.parse_expr(s)
      return nil, s if s.length == 0

      m = /\A@(\w+(::\w+)?)/.match(s)
      raise "Illegal expression #{s}" unless m
      name = m[1]
      s = m.post_match

      attr, s = parse_attr(s)
      if attr
        return {'Fn::GetAtt' => [name, attr]}, s
      else
        map, s = parse_map(s)
        if map
          if map[1] # two arguments found
            return {'Fn::FindInMap' => [name, map[0], map[1]]}, s
          else
            return {'Fn::FindInMap' => [name + 'Map', {'Ref' => name}, map[0]]}, s
          end
        end
      end
      return {'Ref' => name}, s
    end

    def self.parse_map(s)
      bracket, s = parse_left_bracket(s)
      return nil, s unless bracket
      top, s = parse_key(s)
      top, s = parse_expr(s) unless top
      second, s = parse_comma(s)
      second, s = parse_key(s) if second
      second, s = parse_expr(s) if second.nil?
      bracket, s = parse_right_bracket(s)
      raise "Expected closing ']' #{s}" unless bracket
      return [top, second], s
    end

    def self.parse_left_bracket(s)
      m = /\A\[\s*/.match(s)
      return true, m.post_match if m
      return false, s
    end

    def self.parse_right_bracket(s)
      m = /\A\s*\]/.match(s)
      return true, m.post_match if m
      return false, s
    end

    def self.parse_comma(s)
      m = /\A\s*,\s*/.match(s)
      return true, m.post_match if m
      return false, s
    end

    def self.parse_key(s)
      m = /\A(\w+)/.match(s)
      return m[0], m.post_match if m
      return nil, s
    end

    def self.parse_attr(s)
      m = /\A(\.\w+)+/.match(s)
      return m[0][1..-1], m.post_match if m
      return nil, s
    end

  end
end
