require 'test/unit'

p ENV['PATH']
def make_runner(dir)
  klass= Class.new Test::Unit::TestCase do
    test_dir = File.expand_path("test/#{dir}/0*")
    Dir[test_dir].each do |d|
      define_method 'test_'+dir+'_'+d.split("/").last do
        Dir.chdir(d)
        command = File.read('command')
        output= `#{command} 2>&1`
        expected = File.read('output')
        assert_equal expected.chomp.strip, output.chomp.strip
      end
    end
  end
  Object.const_set 'Test_'+dir, klass
end
make_runner 'basic'

