require 'set'
require 'English'
$OUTPUT_FIELD_SEPARATOR = ' '

  def p args
    STDERR.puts(args.inspect) #if $DEBUG
  end

class PseudoBinding
  class PerlVar < String
    def <=> other
      if other.is_a? Numeric
        to_f <=> other
      else
        super
      end
    end
    def inspect
      "PerlVar(#{super})"
    end
  end
  PerlNil = PerlVar.new ''
  attr :line
  def initialize lineno, vals
    @line, @vals = lineno, vals.map {|x| PerlVar.new(x)}
  end
  def method_missing name, *args
    if args.empty?
      if name =~ /_(\d+)/
        @vals[$1.to_i] || PerlNil
      else
        name.to_s
      end
    else
      super
    end
  end
end
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
  VERSION = "0.1.2"
  def self.cmd(&block)
    klass = Struct.new :value, &block
    klass.class_eval do 
      def process(items)
        value.assign(items)
        _process(value)
      end
    end
    klass
  end
  RGX= /"(.*?)"|\[(.*?)\]|([^\s]+)/
  Value = Struct.new :index, :value do
    def assign(items)
      self.value = items[index]
    end
    def process(items)
      items[index]
    end
    def to_i
      value.to_i
    end
    def to_f
      value.to_f
    end
    def to_s
      value.to_s
    end
  end
  Ops = {
    :min => cmd do
      def initialize value
        super
        @running_value = Float::MAX #-Inf would be better
        @result = proc { @running_value }
        @result.single = true
      end
      def _process(value)
        if value.to_f < @running_value  
          @running_value = value.to_f
        end
        @result
      end
    end,
      :max => cmd do
      def initialize index
        super
        @running_value = Float::MIN #-Inf would be better
        @result = proc { @running_value }
        @result.single = true
      end
      def _process(value)
        if value.to_f > @running_value
          @running_value = value.to_f
        end
        @result
      end
      end,
        :sum => cmd do
        def initialize index
          super
          @running_value = 0
          @result = proc { @running_value }
          @result.single = true
        end
        def _process(value)
          @running_value += value.to_i
          @result
        end
    end,
    :avg => cmd do
      def initialize index
        super
        @running_value = 0
        @running_count = 0
        @result = proc { @running_value/@running_count.to_f }
        @result.single = true
      end
      def _process(value)
        @running_value += value.to_i
        @running_count += 1
        @result
      end
    end,
    :freq => cmd do
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
      def _process(value)
        @running_freqs[value.to_s]+=1
        @running_count += 1
        @result
      end
    end,
    :stats => cmd do
      def initialize index
        require 'rubygems'
        require 'ministat'
        super
        @running_values = []
        cached = nil
        @result = proc do  
          unless cached
            data = MiniStat::Data.new(@running_values)
            cached = { 
              "Mean"=>data.mean,
              "Geometric Mean"=>data.geometric_mean,
              "Harmonic Mean"=>data.harmonic_mean,
              "Median"=>data.median ,
              "Min"=>data.data.min ,
              "Q1"=>data.q1,
              "Q3"=>data.q3,
              "Max"=>data.data.max,
              "IQR"=>data.iqr,
              "Outliers"=>data.outliers.inspect,
              "Variance"=>data.variance ,
              "Std Dev"=>data.std_dev,
            }.sort.each
          end
          cached.next
        end
      end
      def _process(value)
        @running_values << value.to_i
        @result
      end
    end,
  }

  def parse(expr)
    val, cond = expr.split(/ if /)
                              # p [ val, cond]
    elems=val.split
    r=elems.map do |e|
      case e
      when /(\w+)\(\_(\d+)\)/
        klass=Ops[$1.to_sym]
        if klass.nil?
          abort "unknown op '#$1'"
        end
        klass.new(Value.new($2.to_i))
      when /\_(\d+)/
        Value.new($1.to_i)
      end
    end
    [r, parse_cond(cond)]
  end

  def parse_cond str
    case str
    when %r[/.*/]
      proc { |bnd| bnd.instance_eval(str) === bnd._0 }
    when nil, ''
      proc { |bnd| true }
    else
    proc { |bnd| bnd.instance_eval(str) }
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
    ast, cond =parse(expr)
    result = []
    result = lines.map.with_index do |line, lineno|
      line.chomp!
      items = [line]+line.scan(RGX).map do |a| 
        # XXX horrible
        a.find do |e| 
          !e.nil? 
        end 
      end
      #XXX ugly
      next unless items
      b = PseudoBinding.new(lineno, items)
      ast.map do |a| 
        a.process(items) if cond[b]
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
      next if result_line.empty?
      puts result_line
      last = cols
    end
  rescue StopIteration
    # end
  end

end
