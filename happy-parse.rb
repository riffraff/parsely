require 'set'
RGX= /"(.*?)"|\[(.*?)\]|([^\s]+)/
  expr = ARGV.shift
expr = ' [' +
  expr.gsub(/\$(\d+)/ , 'immediate(\1)') +
  ']'
def p *args
  super(*args) if $DEBUG
end
p expr
Accumulator = Struct.new :code, :values, :final do
  def transform(ary)
    ary.each do |el|
      code.call el
    end


end
Immediate = Struct.new :final
def uniq *args
  uniq = Set.new
  Accumulator.new( proc { |e| uniq << e}, args, :final)
end
def immediate(*args)
  Immediate.new(*args)
end

result = Array.new
ARGF.each do |line|
  p line
  items = line.scan(RGX).map do |a| 
    a.find do |e| 
      !e.nil? 
    end 
  end
  p items
  __dollar__ = [ "zero is not an item"]  + items
  result << eval(expr)
end

if result.empty?
  exit
end

rules = result.first
rules.each do |rule|

end
result.each do |entry|
  puts entry.map do |item|
    if item.is_a? Accumulator
      item.final
    else
      item
    end
  end
end
