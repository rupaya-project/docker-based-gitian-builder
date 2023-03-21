FROM ubuntu:18.04

MAINTAINER mo-bay <aasim@rupaya.io>

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update && \
    apt-get --no-install-recommends -yq install \
        locales \
        git-core \
        build-essential \
        ca-certificates \
        ruby \
        rsync && \
    apt-get -yq dist-upgrade && \
    locale-gen en_US.UTF-8 && \
    update-locale LANG=en_US.UTF-8

WORKDIR /shared

RUN git clone https://github.com/rupaya-project/gitian-builder /shared/gitian-builder && \
    chown -R ubuntu:ubuntu /shared

RUN echo 'ubuntu ALL=(root) NOPASSWD:/usr/bin/apt-get,/shared/gitian-builder/target-bin/grab-packages.sh' > /etc/sudoers.d/ubuntu && \
    chown root:root /etc/sudoers.d/ubuntu && \
    chmod 0400 /etc/sudoers.d/ubuntu && \
    chown -R ubuntu:ubuntu /home/ubuntu

USER ubuntu

RUN printf "[[ -d /shared/rupaya ]] || \
    git clone -b 5980 --depth 1 https://github.com/rupaya-project/rupaya.git /shared/rupaya && \
    cd /shared/gitian-builder; \
    ./bin/gbuild --skip-image --commit rupaya=5980 --url rupaya=https://github.com/rupaya-project/rupaya.git ../rupaya/contrib/gitian-descriptors/gitian-linux.yml" > /home/ubuntu/runit.sh && \
    chmod +x /home/ubuntu/runit.sh

CMD ["https://github.com/rupaya-project/rupaya","../rupaya/contrib/gitian-descriptors/gitian-linux.yml"]

ENTRYPOINT ["bash", "/home/ubuntu/runit.sh"]
