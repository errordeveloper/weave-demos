FROM errordeveloper/oracle-jdk

ENV LEIN_ROOT 1
ENV HTTP_CLIENT curl -k -s -f -L -o

RUN curl \
  --silent \
  --location \
  --retry 3 \
  --insecure \
  https://raw.githubusercontent.com/technomancy/leiningen/stable/bin/lein \
  --output /usr/bin/lein \
    && chmod 0755 /usr/bin/lein

RUN opkg-install bash ; /usr/bin/lein upgrade

VOLUME [ "/io" ] 
WORKDIR /io


ENTRYPOINT [ "lein" ]
