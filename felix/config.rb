$num_instances=3
$vb_memory=2048

begin
  require File.join(File.dirname(__FILE__), 'config-override.rb')
rescue LoadError => e
end

require 'securerandom'
WEAVE_PASSWORD = SecureRandom.uuid

def genenv_content(count)
  case count
  when 0
    weave_peers=''
  else
    weave_peers='172.17.8.101'
  end

  %W(
    WEAVE_PEERS="#{weave_peers}"
    WEAVE_PASSWORD="#{WEAVE_PASSWORD}"
    WEAVEDNS_ADDR="10.10.2.#{count}/16"
  ).join("\n")
end

def genenv(count)
  {
    'path' => sprintf("/etc/weave.core-%.2d.env", count+1),
    'permissions' => '0600',
    'owner' => 'root',
    'content' => genenv_content(count),
  }
end

if File.exists?('cloud-config.yaml') && ARGV[0].eql?('up')
  require 'yaml'
  open('cloud-config.yaml', 'r') do |f|
    data = YAML.load(f)

    data['write_files'] = $num_instances.times.map { |x| genenv(x) }

    data['write_files'] << {
      'path' => '/run/docker_opts.env',
      'permissions' => '0600',
      'owner' => 'root',
      'content' => "DOCKER_OPTS='--insecure-registry=\"0.0.0.0/0\" --icc=false'\n"
    }

    open('user-data', 'w') do |f|
      lines = YAML.dump(data).split("\n")
      lines[0] = '#cloud-config'
      f.puts(lines)
    end
  end
end
