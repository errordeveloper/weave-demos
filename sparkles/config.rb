$num_instances=3
$vb_memory=2048

require 'securerandom'
$password = SecureRandom.uuid

def genenv_content(count)
  case count
  when 0
    known_weave_nodes=''
    spark_node_role='master'
    spark_container_args=''
    spark_node_name="spark-#{spark_node_role}.weave.local"
  else
    known_weave_nodes='172.17.8.101'
    spark_node_role='worker'
    spark_container_args='spark://spark-master.weave.local:7077'
    spark_node_name="spark-#{spark_node_role}-#{count}.weave.local"
  end

  weavedns_addr="10.10.2.1#{count}/16"
  spark_node_addr="10.10.1.1#{count}/24"
  elasticsearch_node_addr="10.10.1.2#{count}/24"

  %W(
    WEAVE_PEERS="#{known_weave_nodes}"
    WEAVE_PASSWORD="#{$password}"
    WEAVEDNS_ADDR="#{weavedns_addr}"
    SPARK_NODE_ADDR="#{spark_node_addr}"
    SPARK_NODE_NAME="#{spark_node_name}"
    SPARK_CONTAINER="errordeveloper/weave-spark-#{spark_node_role}-minimal:latest"
    SPARK_CONTAINER_ARGS="#{spark_container_args}"
    ELASTICSEARCH_NODE_ADDR="#{elasticsearch_node_addr}"
    ELASTICSEARCH_NODE_NAME="elasticsearch-#{count}.weave.local"
    ELASTICSEARCH_CONTAINER="errordeveloper/weave-twitter-river-minimal:latest"
  ).join("\n")
end

def genenv(count)
  {
    'path' => sprintf("/etc/weave.core-%.2d.env", count+1),
    'permissions' => 0644,
    'owner' => 'root',
    'content' => genenv_content(count),
  }
end

if File.exists?('cloud/cloud-config.yaml') && ARGV[0].eql?('up')
  require 'yaml'

  data = YAML.load(IO.readlines('cloud/cloud-config.yaml')[1..-1].join)

  $num_instances.times { |x| data['write_files'] << genenv(x) }

  data['coreos']['units'] << {
    'name' => 'fix-env-file-path.service',
    'command' => 'start',
    'enable' => true,
    'content' =>
      "[Unit]\n" \
      "Before=install-weave.service\n" \
      "[Service]\n" \
      "Type=oneshot\n" \
      "ExecStart=/bin/ln -s /etc/weave.%H.env /etc/weave.env\n"
  }

  data['coreos']['units'] << {
    'name' => 'provisioning-completed.target',
    'command' => 'start',
    'enable' => true,
    'content' =>
      "[Unit]\n" \
      "Requires=weave.service elasticsearch.service spark.service\n" \
      "RefuseManualStart=no\n" \
      "Wants=weave.service elasticsearch.service spark.service\n" \
      "[Install]\n" \
      "WantedBy=multi-user.target\n" \
  }

  lines = YAML.dump(data).split("\n")
  lines[0] = '#cloud-config'

  open('user-data', 'w') do |f|
    f.puts(lines.join("\n"))
  end
end
