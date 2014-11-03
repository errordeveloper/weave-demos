# Automatically set the discovery token on 'vagrant up'

if File.exists?('kubernetes-cluster.yaml') && ARGV[0].eql?('up')
  require 'open-uri'
  require 'yaml'

  token = open('https://discovery.etcd.io/new').read

  data = YAML.load(IO.readlines('kubernetes-cluster.yaml')[1..-1].join)
  data['coreos']['etcd']['discovery'] = token

  lines = YAML.dump(data).split("\n")
  lines[0] = '#cloud-config'

  open('user-data', 'r+') do |f|
    f.puts(lines.join("\n"))
  end
end

$num_instances=3
