FROM ubuntu:bionic
MAINTAINER mobay <aasim@rupx.io>

ENV DEBIAN_FRONTEND=noninteractive

# Install required packages
RUN apt-get update \
  && apt-get --no-install-recommends -yq install \
    locales \
    git \
    build-essential \
    ca-certificates \
    ruby \
    rsync \
  && apt-get -yq purge grub > /dev/null 2>&1 || true \
  && apt-get -y dist-upgrade \
  && rm -rf /var/lib/apt/lists/*

# Configure locale
RUN locale-gen en_US.UTF-8 \
  && update-locale LANG=en_US.UTF-8

# Clone gitian-builder if it doesn't exist
RUN git clone https://github.com/rupaya-project/gitian-builder /shared/gitian-builder \
  || echo "gitian-builder already exists"

# Set ownership of shared directory to ubuntu user
RUN chown -R 1000:1000 /shared/

# Allow ubuntu user to run apt-get and grab-packages.sh with sudo without password
RUN echo 'ubuntu ALL=(root) NOPASSWD:/usr/bin/apt-get,/shared/gitian-builder/target-bin/grab-packages.sh' > /etc/sudoers.d/99_ubuntu \
  && chmod 0440 /etc/sudoers.d/99_ubuntu \
  && chown root:root /etc/sudoers.d/99_ubuntu \
  && chown root:root /shared/gitian-builder/target-bin/grab-packages.sh \
  && chmod 755 /shared/gitian-builder/target-bin/grab-packages.sh

# Create ubuntu user and set ownership of home directory
RUN useradd -d /home/ubuntu -m -s /bin/bash -u 1000 ubuntu \
  && chown -R 1000:1000 /home/ubuntu

# Switch to ubuntu user
USER ubuntu

# Set up runit script
RUN printf "[[ -d /shared/rupaya ]] || \
git clone -b \$1 --depth 1 \$2 /shared/rupaya && \
cd /shared/gitian-builder; \
./bin/gbuild --skip-image --commit rupaya=\$1 --url rupaya=\$2 \$3" > /home/ubuntu/runit.sh \
  && chmod +x /home/ubuntu/runit.sh

ENTRYPOINT ["bash", "/home/ubuntu/runit.sh"]
CMD ["5980","https://github.com/rupaya-project/rupaya","../rupaya/contrib/gitian-descriptors/gitian-linux.yml"]



