require 'rubygems'
require 'bundler/setup'

# not a constant so we don't pollute global namespace
release_ops_path = File.expand_path('../../releaseops/lib', __FILE__)

if File.exists?(release_ops_path)
  require File.join(release_ops_path, 'releaseops')
  ReleaseOps::SimpleCov.maybe_start
end


Bundler.require(:development, :test)

require 'zk'
require 'benchmark'

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[File.expand_path("../{support,shared}/**/*.rb", __FILE__)].sort.each {|f| require f}

$stderr.sync = true

require 'flexmock'

RSpec.configure do |config|
  config.mock_with :flexmock
  config.include(FlexMock::ArgumentTypes)

  [WaitWatchers, SpecGlobalLogger, Pendings].each do |mod|
    config.include(mod)
    config.extend(mod)
  end

  if ZK.spawn_zookeeper?
    require 'zk-server'

    config.before(:suite) do 
      ZK.logger.debug { "Starting zookeeper service" }
      ZK::Server.run do |c|
        c.client_port = ZK.test_port
        c.force_sync  = false
        c.snap_count  = 1_000_000
      end
    end

    config.after(:suite) do
      ZK.logger.debug { "stopping zookeeper service" }
      ZK::Server.shutdown
    end
  end
end

class ::Thread
  # join with thread until given block is true, the thread joins successfully, 
  # or timeout seconds have passed
  #
  def join_until(timeout=2)
    time_to_stop = Time.now + timeout

    until yield
      break if Time.now > time_to_stop
      break if join(0)
      Thread.pass
    end
  end
  
  def join_while(timeout=2)
    time_to_stop = Time.now + timeout

    while yield
      break if Time.now > time_to_stop
      break if join(0)
      Thread.pass
    end
  end
end


