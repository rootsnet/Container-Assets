FROM ubuntu:24.04

USER root

# Prevent interactive prompts during package installation
ARG DEBIAN_FRONTEND=noninteractive
ARG DISPLAY=localhost:0.0
RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections
RUN dpkg-divert --local --rename --add /sbin/initctl
RUN ln -sf /bin/true /sbin/initctl
RUN echo "#!/bin/sh\nexit 0" > /usr/sbin/policy-rc.d

# Install only what we need for nft-sidecar
RUN apt-get update -q && \
    apt-get install --no-install-recommends -y -q \
        ca-certificates \
        iproute2 \
        nftables \
        coreutils \
        tzdata \
        locales && \
    apt-get autoremove -y -q && \
    apt-get clean -y -q && \
    rm -rf /var/lib/apt/lists/* /usr/share/doc /usr/share/man /var/cache/* && \
    localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8

# Set environment variables
ENV LANG en_US.utf8
ENV TZ=Asia/Seoul

# Configure timezone
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && \
    echo $TZ > /etc/timezone

# Remove tools we do NOT want at runtime (lock down the image)
RUN apt-get update -q || true; \
    apt-get purge -y -q --auto-remove \
        openssh-client openssh-server \
        netcat-openbsd \
        net-tools \
        iputils-ping \
        telnet \
        traceroute \
        curl \
        wget \
        apt-utils || true; \
    dpkg --purge --force-all gpgv gnupg gnupg-utils || true; \
    dpkg --purge --force-all apt apt-utils || true; \
    rm -f /usr/bin/apt /usr/bin/apt-get /usr/bin/apt-cache /usr/bin/apt-config \
          /usr/bin/gpgv /usr/bin/gpg /usr/bin/gpgconf /usr/bin/gpg-agent || true; \
    rm -rf /etc/apt /var/lib/apt /var/cache/apt /var/lib/apt/lists/* /root/.gnupg || true; \
    rm -f /bin/apt /bin/apt-get /usr/local/bin/apt /usr/local/bin/apt-get || true

# Create directory for scripts
RUN mkdir -p /opt/nft

# Copy entrypoint script
COPY entrypoint.sh /opt/nft/entrypoint.sh
RUN chmod +x /opt/nft/entrypoint.sh

# Default environment
COPY nft-rules.nft /opt/nft/nft-rules.nft
ENV NFT_RULES=/opt/nft/nft-rules.nft

WORKDIR /opt/nft

USER 0

ENTRYPOINT ["/opt/nft/entrypoint.sh"]

