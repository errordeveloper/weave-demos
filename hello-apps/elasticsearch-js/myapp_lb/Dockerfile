FROM nginxplus

ARG weavedns_addr

RUN echo "resolver ${weavedns_addr} ipv6=off;" > /etc/nginx/conf.d/weavedns.conf

ADD myapp.conf /etc/nginx/conf.d/default.conf
