require 'mu'
require 'parsely_expression'


P = ParselyExprParser.new
t 'value to_s works' do
  is "value(x)", Parsely::Value.new(:x).to_s
end
t 'expression parses value' do
 is "value($1)", P.parse("$1").to_s 
end
t 'expression parses multiple values' do
 is "value($1) value($2)", P.parse("$1 $2").to_s 
end
t 'expression parses op' do
 is "op:avg", P.parse("avg").to_s 
end
