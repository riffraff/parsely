require 'set'
require 'English'
$OUTPUT_FIELD_SEPARATOR = ' '
module Kernel
  def p args
    STDERR.puts(args.inspect) #if $DEBUG
  end
end

class PseudoBinding
  class PerlVar < String
    # this is not defined in terms of <=>
    def == other
      if other.is_a? Numeric
        to_f == other
      else
        super
      end
    end
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
    #unneed as of now
    #def coerce something
    #  [something, to_f]
    #end
    def + other
      case other
      when Numeric
        PerlVar.new((to_i + other).to_s)
      when String
        PerlVar.new((to_s + other).to_s)
      end
    end
  end
  PerlNil = PerlVar.new ''
  attr :line
  attr :vals
  def initialize lineno, vals
    @line, @vals = PerlVar.new(lineno.to_s), vals.map {|x| PerlVar.new(x)}
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
class Array
  def value
    self
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
  VERSION = "0.1.4"
  def self.cmd(&block)
    Struct.new :value, &block
  end
  RGX= /"(.*?)"|\[(.*?)\]|([^\s]+)/

  Expression = Struct.new :code, :items do
    def process(pb)
      result = pb.instance_eval(code)
    end
    def to_s
      code.to_s
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
      def process(value)
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
      def process(value)
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
      def process(value)
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
      def process(value)
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
      def process(value)
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
      def process(value)
        @running_values << value.to_i
        @result
      end
    end,
  }
  PseudoBinding.class_eval do
    Ops.each do |k,v|
      #instantiating the object is expensive and we are not using 99% of them
      obj = nil
      define_method k do |values|
        obj ||= v.new(nil)
        obj.process(values)
      end
    end
  end

  def parse(expr)
    val, cond = expr.split(/ if /)
                              # p [ val, cond]

    val = '['+val+']'
    if val =~ /([\(\)\w])( ([\(\)\w]))+/
      val = val.split(" ").join(",")
    end
    r = Expression.new(val)
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

  def load_rc
    rcfile = if  ENV["PARSELYRC"]
      ENV["PARSELYRC"]
    else
      home = ENV["HOME"] || Dir.pwd
      home+"/.parselyrc"
      #_parsely, $parsely etc
    end
    if File.exists?(rcfile)
      load rcfile
    end
  end

  def main
    if ARGV.empty?
      abort("usage #$0 <expr> <file file file| stdin >")
    end
    load_rc
    expr = ARGV.shift
    main_loop(expr,ARGF)
  end

  def main_loop(expr,lines)
    expression, cond =parse(expr)
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
      expression.process(b) if cond[b]
    end
    last = []
    result.each do |cols|
      next if cols.nil? #when test fails
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
