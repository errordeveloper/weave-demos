#!/bin/sh
cloud="${1}"
count="${2}"
node_alias="node-${cloud}-${count}"
ssh_key_path="${3}"
ip_addr="${4}"

cat << WRAPPER > ./ssh_${node_alias}
  #!/bin/sh
  ssh core@${ip_addr} \
  -o Compression=yes \
  -o LogLevel=FATAL \
  -o StrictHostKeyChecking=no \
  -o UserKnownHostsFile=/dev/null \
  -o IdentitiesOnly=yes \
  -o IdentityFile=${ssh_key_path} \
  \$@
WRAPPER
chmod +x ./ssh_${node_alias}
