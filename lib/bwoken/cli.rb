require 'slop'

%w(version cli/init cli/test).each do |f|
  require File.expand_path("../#{f}", __FILE__)
end

ran_command = nil

opts = Slop.parse :help => true do
  on :v, :version, 'Print the version' do
    puts Bwoken::VERSION
    exit 0
  end

  command 'init' do
    banner Bwoken::CLI::Init.help_banner
    on :'integration-path=', 'Specify a custom directory to store your test scripts in (e.g. --integration-path=uiautomation/path/dir). Default: integration. If you use the non-default value here, you will need to always run bwoken with the `--integration-path=your/integration/dir` option.', :default => 'integration'

    run { ran_command = 'init' }
  end

  command 'test' do
    banner Bwoken::CLI::Test.help_banner

    on :simulator, 'Use simulator, even when an iDevice is connected', :default => false
    on :device=, 'Use given device (name or id)', :default => nil

    on :family=, 'Test only one device type, either ipad or iphone. Default is to test on both',
      :match => /\A(?:ipad|iphone|all)\Z/i, :default => 'all'
    on :scheme=, 'Specify a custom scheme'
    on :'product-name=', 'Specify a custom product name (e.g. --product-name="My Product"). Default is the name of of the xcodeproj file'
    on :'integration-path=', 'Specify a custom directory to store your test scripts in (e.g. --integration-path=uiautomation/path/dir). Note that this folder still expects the same directory structure as the one create by `bwoken init`.', :default => 'integration'
    #on :flags=, 'Specify custom build flags (e.g., --flags="-arch=i386,foo=bar")', :as => Array, :default => [] # TODO: implement
    on :formatter=, 'Specify a custom formatter (e.g., --formatter=passthru)', :default => 'colorful'
    on :focus=, 'Specify particular tests to run', :as => Array, :default => []
    on :clobber, 'Remove any generated file'
    on :'skip-build', 'Do not build the iOS binary'
    on :configuration=, 'The build configruation to use (e.g., --configuration=Release)', :default => 'Debug'
    on :'sdk-version=', 'The SDK version to use (e.g., --sdk-version=6.1)'
    on :verbose, 'Be verbose'
    on :junit, 'Create junit xml test results'

    run { ran_command = 'test' }
  end

end

if File.exists?('Rakefile')
  contents = open('Rakefile').read.strip
  if contents =~ /\Arequire ["']bwoken\/tasks["']\Z/
    STDERR.puts 'You may safely delete Rakefile'
  elsif contents =~ /require ["']bwoken\/tasks["']/
    STDERR.puts %Q|You may safely remove the "require 'bwoken/tasks'" line from Rakefile|
  end
end

case ran_command
when 'init' then Bwoken::CLI::Init.new(opts.commands['init']).run
when 'test' then Bwoken::CLI::Test.new(opts.commands['test']).run
else puts opts
end
