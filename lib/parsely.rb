require 'set'
require 'English'
$OUTPUT_FIELD_SEPARATOR = ' '
class String
  def value
    to_s
  end
end
class Proc
  attr_accessor :single
  def value
    call
  end
end
class Parsely
  RGX= /"(.*?)"|\[(.*?)\]|([^\s]+)/

  def p args
    STDERR.puts(args.inspect) #if $DEBUG
  end

  Value = Struct.new :index do
    def process(items)
      items[index]
    end
  end
  Ops = {
    :sum => Struct.new(:index) do
      def initialize index
        super
        @running_value = 0
        @result = proc { @running_value }
        @result.single = true
      end
      def process(items)
        #p [:sum, items,items[index-1].to_i, @accumulator.value]
        @running_value += items[index].to_i
        @result
      end
    end,
    :avg => Struct.new(:index)do
      def initialize index
        super
        @running_value = 0
        @running_count = 0
        @result = proc { @running_value/@running_count.to_f }
        @result.single = true
      end
      def process(items)
        #p [:sum, items,items[index-1].to_i, @accumulator.value]
        @running_value += items[index].to_i
        @running_count += 1
        @result
      end
    end,
    :freq => Struct.new(:index)do
      def initialize index
        super
      	@running_freqs = Hash.new(0)
        @running_count = 0
	as_ary=nil
        @result = proc do
          if as_ary.nil?
            as_ary=@running_freqs.sort_by do |k,v| [-v,k] end.each
          end
          k,v = as_ary.next 
          [v, k]
        end
      end
      def process(items)
        #p [:sum, items,items[index-1].to_i, @accumulator.value]
        @running_freqs[items[index]]+=1
        @running_count += 1
        @result
      end
    end
  }

  def parse(expr)
    elems=expr.split
    elems.map do |e|
      case e
      when /(\w+)\(\_(\d+)\)/
        Ops[$1.to_sym].new($2.to_i)
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
      items = [line]+line.scan(RGX).map do |a| 
        # XXX
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
        next if col.nil?
        col.value 
      end.join.strip 
      same_results = cols.zip(last).map do |a,b| 
        a.respond_to?(:single) && a.single && a.object_id == b.object_id && !a.is_a?(Numeric) 
      end.all?
      break if same_results
      puts result_line
      last = cols
    end
  rescue StopIteration
    # end
  end

end
