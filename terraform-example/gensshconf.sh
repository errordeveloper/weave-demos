#!/bin/sh
cloud="${1}"
count="${2}"
node_alias="node-${cloud}-${count}"
ssh_key_path="${3}"
ip_addr="${4}"

ssh_conf_body="
Host ${node_alias}
  Hostname ${ip_addr}
  User core
  Compression yes
  LogLevel FATAL
  StrictHostKeyChecking no
  UserKnownHostsFile /dev/null
  IdentitiesOnly yes
  IdentityFile ${ssh_key_path}
"

if [ ${count} -eq 0 ]; then
  echo "${ssh_conf_body}" > ./ssh_conf_${cloud}
else
  echo "${ssh_conf_body}" >> ./ssh_conf_${cloud}
fi
