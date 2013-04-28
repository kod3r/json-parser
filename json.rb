require 'parslet'

class JSON < Parslet::Parser

  rule(:space) { (match('\s')).repeat(1) }
  rule(:space?) { space.maybe }

  rule(:string) {
    str('"') >>
    ((str('\\') >> any) | (str('"').absent? >> any)).repeat.as(:string) >>
    str('"')
  }

  rule(:digit) { match('[0-9]') }

  rule(:number) {
    str('-').maybe >>
    (str('0') | (match('[1-9]') >> digit.repeat)) >>
    (str('.') >> digit.repeat(1)).maybe >>
    (
      (str('e') | str('E')) >>
      (str('+') | str('-')).maybe >>
      digit.repeat(1)
    ).maybe
  }

  rule(:value) { space? >>
    (
      string |
      number.as(:number) |
      object |
      array |
      str('true').as(:true) |
      str('false').as(:false) |
      str('null').as(:null)
    ) >>
    space?
  }

  rule(:array) {
    str('[') >>
    (value >> (str(',') >> value).repeat.maybe).maybe.as(:array) >>
    space? >>
    str(']')
  }

  rule(:member) {
    space? >>
    string.as(:name) >>
    space? >>
    str(':') >>
    value.as(:value)
  }

  rule(:members) { member >> (str(',') >> member).repeat }

  rule(:object) { str('{') >> members.maybe.as(:object) >> str('}') }

  root(:value)
end

class Ruby < Parslet::Transform

  rule(:object => subtree(:object)) {
    case object
      when Hash
        {object[:name] => object[:value]}
      when Array
        object.inject({}) do |l, o|
          l[o[:name]] = o[:value]; l
        end
      else
        {}
    end
  }

  rule(:array => subtree(:array)) {
    case
      when array.respond_to?(:to_a)
        array.to_a
      else
        [array]
    end
  }

  rule(:string => simple(:string)) {
    s = string.to_s
    s.gsub!('\"', '"')
    s.gsub!('\\\\', '\\')
    s.gsub!('\/', '/')
    s.gsub!('\b', "\b")
    s.gsub!('\f', "\f")
    s.gsub!('\n', "\n")
    s.gsub!('\r', "\r")
    s.gsub!('\t', "\t")
    s.gsub!(/\\u([0-4]{4})/) { |m| [$1].pack("H*").unpack("n*").pack("U*") }
    s
  }

  rule(:number => simple(:number)) { number.to_s.include?('.') ? Float(number) : Integer(number) }

  rule(:true => simple(:true)) { true }
  rule(:false => simple(:false)) { false }
  rule(:null => simple(:null)) { nil }

end