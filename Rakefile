ENV['PATH']+=':'+File.join(File.dirname(__FILE__),'bin/')
ENV['RUBYLIB']||=''
ENV['RUBYLIB']+=':'+File.join(File.dirname(__FILE__),'lib/')
task :default => [:test]

task :test do
  ruby "-Ilib test/cli-runner.rb"
end

task :newtest do
  old = Dir.entries('test/basic/').last
  new = old.succ
  cp_r 'test/basic/'+old, 'test/basic/'+new
end
