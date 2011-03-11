require 'set'
require 'english'
$OUTPUT_FIELD_SEPARATOR = ' '
class Parsely
  RGX= /"(.*?)"|\[(.*?)\]|([^\s]+)/

  def p *args
    super(args) if $DEBUG
  end

  Value = Struct.new :index do
    def to_s
      "value(#{index})"
    end
  end
  Operation = Struct.new :opname do
    def to_s
      "op:#{opname}"
    end
  end
  def parse(expr)
    elems=expr.split
    elems.map do |e|
      case e
      when /\$\d+/
        Value.new(e)
      when /\w+/
        Operation.new(e)
      end
    end
  end
  def main
    if ARGV.empty?
      abort("usage #$0 <expr> <file file file| stdin >")
    end
    expr = ARGV.shift
    p :argv, ARGV
    expr = ' [' +
      expr.gsub(/\_(\d+)/ , '__dollar__[\1]') +
      ']'

    main_loop(expr,ARGF)
  end

  def main_loop(expr,lines)

    p :eprelines, expr, lines
    result = Array.new
    lines.each do |line|
      p :line, line
      items = line.scan(RGX).map do |a| 
        a.find do |e| 
          !e.nil? 
        end 
      end
      p :items, items
      __dollar__ = [ "zero is not an item"]  + items
      result << eval(expr)
    end

    if result.empty?
      exit
    end

    p :result, result
    result.each do |entry|
      p :entry, entry
      p :entry, entry.to_s
      outline = entry.map do |item|
        if item.is_a? Operation
          item.final
        else
          item
        end
      end.join($OUTPUT_FIELD_SEPARATOR) rescue next #implicitly would be that anyway
      p :outline, outline
      puts outline
    end
  end

end
