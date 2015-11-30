for m in 'core-01' 'core-02' 'core-03'
do vagrant ssh $m --command 'docker pull errordeveloper/weave-elasticsearch-minimal:latest'
done

vagrant ssh 'core-01' --command 'docker pull errordeveloper/iojs-minimal-runtime:v1.0.1'
vagrant ssh 'core-01' --command 'git clone https://github.com/errordeveloper/weave-demos'
