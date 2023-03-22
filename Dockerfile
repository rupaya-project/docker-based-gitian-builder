# Base image
FROM ubuntu:bionic

# Metadata
LABEL maintainer="mobay@rupaya.io"

# Environment variables
ENV DEBIAN_FRONTEND noninteractive
WORKDIR /shared

# Install required packages and dependencies
RUN apt-get update && \
    apt-get --no-install-recommends -yq install \
    locales \
    git-core \
    build-essential \
    ca-certificates \
    ruby \
    rsync && \
    apt-get -yq purge grub > /dev/null 2>&1 || true && \
    apt-get install sudo wget > /dev/null 2>&1 || true && \
    apt-get -y dist-upgrade && \
    locale-gen en_US.UTF-8 && \
    update-locale LANG=en_US.UTF-8

# Create a directory and clone gitian-builder
RUN mkdir /home/ubuntu/ && \
    bash -c '[[ -d /shared/gitian-builder ]] || git clone https://github.com/rupaya-project/gitian-builder /shared/gitian-builder' && \
    chmod -R 775 /shared/gitian-builder/target-bin/

# Download MacOSX10.14.sdk.tar.gz if specified in build arguments
ARG BUILD_ARG
RUN if [ "$BUILD_ARG" = *"osx"* ]; then \
    mkdir -p /shared/gitian-builder/inputs/ && \
    wget https://bitcoincore.org/depends-sources/sdks/Xcode-11.3.1-11C505-extracted-SDK-with-libcxx-headers.tar.gz -O /shared/gitian-builder/inputs/Xcode-11.3.1-11C505-extracted-SDK-with-libcxx-headers.tar.gz; \
    fi

# Set the user to root and create a script to run the build process
USER root
RUN printf "[[ -d /shared/rupaya ]] || \
    git clone https://github.com/rupaya-project/rupaya /shared/rupaya && \
    cd /shared/gitian-builder; \
    ./bin/gbuild --skip-image --commit rupaya=\$1 --url rupaya=\$2 \$3" > /root/runit.sh

# Default command and entrypoint
CMD ["5980","https://github.com/rupaya-project/rupaya","../rupaya/contrib/gitian-descriptors/gitian-osx.yml"]
ENTRYPOINT ["sudo","bash", "/root/runit.sh"]
