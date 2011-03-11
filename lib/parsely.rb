require 'set'
require 'english'
$OUTPUT_FIELD_SEPARATOR = ' '
class Parsely
  RGX= /"(.*?)"|\[(.*?)\]|([^\s]+)/

    def p args
      STDERR.puts(args.inspect) #if $DEBUG
    end

  Value = Struct.new :index do
    def to_s
      "value(#{index})"
    end
    def process(items)
      res = items[index-1]
      def res.value
        to_s
      end
      res
    end
  end
  Sum = Struct.new :index do
    @@running_value = 0
    def to_s
      "sum(#{inded})"
    end
    Result = proc {@@running_value}
    def Result.value
      call
    end
    def process(items)
      @@running_value += items[index-1].to_i
      Result
    end
  end
  def parse(expr)
    elems=expr.split
    elems.map do |e|
      case e
      when /sum\(\_(\d+)\)/
        Sum.new($2.to_i)
      when /\_(\d+)/
        Value.new($1.to_i)
      end
    end
  end
  def main
    if ARGV.empty?
      abort("usage #$0 <expr> <file file file| stdin >")
    end
    expr = ARGV.shift
    main_loop(expr,ARGF)
  end

  def main_loop(expr,lines)
    ast=parse(expr)
    result = []
    result = lines.map do |line|
      items = line.scan(RGX).map do |a| 
        a.find do |e| 
          !e.nil? 
        end 
      end
      ast.map do |a| 
        a.process(items)
      end 
    end
    p result
    result.each do |cols|
      p cols
      result_line = cols.map do |col|
        p col
        p col.value
        col.value
      end.join
      puts result_line
    end
  end

end
