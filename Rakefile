ENV['PATH']+=':'+File.join(File.dirname(__FILE__),'bin/')
ENV['RUBYLIB']||=''
ENV['RUBYLIB']+=':'+File.join(File.dirname(__FILE__),'lib/')
task :default => [:test]

desc 'run tests'
task :test do
  ruby "-Ilib test/cli-runner.rb"
end

desc 'create new test dir'
task :newtest, :name do |t, args|
  old = Dir.entries('test/basic/').last
  new = old[/^(\d+)/, 1].succ
  new = new + '-' + args[:name] if args[:name]
  cp_r 'test/basic/'+old, 'test/basic/'+new
end
