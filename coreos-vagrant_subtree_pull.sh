git ls-remote https://github.com/coreos/coreos-vagrant master \
  | awk '{ system( "git subtree pull --message=\"Subtree merge of coreos/coreos-vagrant@" $1 "\" --prefix=coreos-vagrant https://github.com/coreos/coreos-vagrant " $1) }'
