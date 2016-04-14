
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
    # expr   : '@' '{'? name (attr+ | map)? '}'?;
    # name   : ID ('::' ID)?;
    # attr   : ('.' ID)+;
    # map    : '[' key (',' key)? ']';
    # key    : ID | expr;
    # ID     : [a-zA-Z0-9]+;
    # RAW    : (~['@']* | FILE)=;
    # FILE   : '@file://' [^@\s]+ ('@' | ' ');
    # FILE_C : '@{file://' [^}] '}';
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

        file_match = /\A@file:\/\/([^@\s]+)@?/.match(s[i..-1])
        file_curly_match = /\A@\{file:\/\/([^\}]+)\}/.match(s[i..-1])
        if file_match # inline file
          s = s[0, i] + File.read(file_match[1]) + file_match.post_match
        elsif file_curly_match # inline file with curly braces
          s = s[0, i] + File.read(file_curly_match[1]) + file_curly_match.post_match
        elsif s[i, 2] !~ /\A@[\w{]/ # escape
          s = s[0, i] + s[i+1..-1]
          i += 1
        else
          return s[0, i], s[i..-1] # return raw, '@...'
        end
      end
    end

    #
    # Parse given string as AutoStacker24 expression, and produce CloudFormation
    # function from it (Fn::GetAtt, Fn::FindInMap, Ref).
    #
    # == Parameters:
    # s::
    #  the string to parse
    # embedded::
    #  whether the string is embedded in an AutoStacker24 expression already.
    #  Embedded expressions may start with '@{', and may only start with '@'.
    #
    def self.parse_expr(s, embedded = false)
      return nil, s if s.length == 0

      at, s = parse(AT, s)
      raise "expected '@' but got #{s}" unless at
      curly, s = parse(LEFT_CURLY, s) unless embedded
      name, s = parse(NAME, s)
      raise "expected parameter name #{s}" unless name

      if embedded
        # try attribute, then map, then fallback to simple ref.
        expr, s = parse_attribute(s, name)
        expr, s = parse_map(s, name)       unless expr
        expr, s = parse_reference(s, name) unless expr

      elsif curly
        # try attribute, then map, then fallback to simple ref.
        expr, s = parse_attribute(s, name)
        expr, s = parse_map(s, name)       unless expr
        expr, s = parse_reference(s, name) unless expr

        closing_curly, s = parse(RIGHT_CURLY, s)
        raise "expected '}' but got #{s}" unless closing_curly
      else
        # allow only simple ref.
        expr, s = parse_reference(s, name)
      end

      return expr, s
    end

    def self.parse_reference(s, name)
      return {'Ref' => name}, s
    end

    def self.parse_attribute(s, name)
      attr, s = parse(ATTRIB, s)
      if attr
        return {'Fn::GetAtt' => [name, attr[1..-1]]}, s
      else
        return nil, s
      end
    end

    def self.parse_map(s, name)
      bracket, s = parse(LEFT_BRACKET, s)
      return nil, s unless bracket
      top, s = parse(KEY, s)
      top, s = parse_expr(s, nested=true) unless top
      comma, s = parse(COMMA, s)
      second, s = parse(KEY, s) if comma
      second, s = parse_expr(s, embedded=true) if comma and second.nil?
      bracket, s = parse(RIGHT_BRACKET, s)
      raise "Expected closing ']' #{s}" unless bracket
      map = [top, second]
      if second # two arguments found
        return {'Fn::FindInMap' => [name, top, second]}, s
      else
        return {'Fn::FindInMap' => [name + 'Map', {'Ref' => name}, top]}, s
      end
    end

    def self.parse(re, s)
      m = re.match(s)
      return m.to_s, m.post_match if m
      return nil, s
    end

    # Tokens
    AT = /\A@/
    NAME = /\A\w+(::\w+)?/
    LEFT_BRACKET = /\A\[\s*/
    RIGHT_BRACKET = /\A\s*\]/
    LEFT_CURLY = /\A\{/
    RIGHT_CURLY = /\A\}/
    COMMA = /\A\s*,\s*/
    KEY = /\A(\w+)/
    ATTRIB = /\A(\.\w+)+/
  end
end
