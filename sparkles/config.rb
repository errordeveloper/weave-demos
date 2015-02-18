if ENV['WEAVE_PASSWORD'] and ENV['WEAVE_PEERS'] then
  require File.join(File.dirname(__FILE__), "join-remote-weave-cluster.rb")
else
  require File.join(File.dirname(__FILE__), "local-cluster.rb")
end
