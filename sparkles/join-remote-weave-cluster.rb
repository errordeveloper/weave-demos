$num_instances=1
$vb_memory=2048

$password = ENV['WEAVE_PASSWORD']
$known_weave_nodes = ENV['WEAVE_PEERS']

$weavedns_addr = '10.10.254.1/16'

def genenv_content()
  %W(
    WEAVE_PEERS="#{$known_weave_nodes}"
    WEAVE_PASSWORD="#{$password}"
    WEAVEDNS_ADDR="#{$weavedns_addr}"
  ).join("\n")
end

def genenv()
  {
    'path' => "/etc/weave.env",
    'permissions' => '0600',
    'owner' => 'root',
    'content' => genenv_content(),
  }
end

if File.exists?('cloud/cloud-config.yaml') && ARGV[0].eql?('up')
  require 'yaml'

  data = YAML.load(IO.readlines('cloud/cloud-config.yaml')[1..-1].join)

  data['write_files'] << genenv()

  data['coreos']['units'] << {
    'name' => 'provisioning-completed.target',
    'command' => 'start',
    'enable' => true,
    'content' =>
      "[Unit]\n" \
      "Requires=weave.service\n" \
      "RefuseManualStart=no\n" \
      "Wants=weave.service\n" \
      "[Install]\n" \
      "WantedBy=multi-user.target\n" \
  }

  lines = YAML.dump(data).split("\n")
  lines[0] = '#cloud-config'

  open('user-data', 'w') do |f|
    f.puts(lines.join("\n"))
  end
end
