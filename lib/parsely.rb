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
   
    def to_s
      "sum(#{inded})"
    end
    running_value = 0
    Accumulator = proc {|add| running_value+=add}
    def Accumulator.value
      call 0
    end
    def process(items)
      #p [:sum, items,items[index-1].to_i, Accumulator.value]
      Accumulator.call items[index-1].to_i
      Accumulator
    end
  end
  def parse(expr)
    elems=expr.split
    elems.map do |e|
      case e
      when /sum\(\_(\d+)\)/
        Sum.new($1.to_i)
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
    last = []
    result.each do |cols|
      result_line = cols.map do |col|
        col.value
      end.join
      same_results = cols.zip(last).map do |a,b| 
        a.object_id == b.object_id && !a.is_a?(Numeric) 
      end.all?
      break if same_results
      puts result_line
      last = cols
    end
  end

end
