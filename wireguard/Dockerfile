FROM ubuntu:24.04

USER root

# Prevent interactive prompts during package installation
ARG DEBIAN_FRONTEND=noninteractive
ARG DISPLAY=localhost:0.0
RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections
RUN dpkg-divert --local --rename --add /sbin/initctl
RUN ln -sf /bin/true /sbin/initctl
RUN echo "#!/bin/sh\nexit 0" > /usr/sbin/policy-rc.d

# Install only what we need for WireGuard
RUN apt-get update -q && \
    apt-get install --no-install-recommends -y -q \
        ca-certificates \
        iproute2 \
        wireguard-tools \
        tzdata \
        locales && \
    apt-get autoremove -y -q && \
    apt-get clean -y -q && \
    localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8

# Set environment variables
ENV LANG en_US.utf8
ENV TZ=Asia/Seoul

# Configure timezone
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && \
    echo $TZ > /etc/timezone

# Remove tools we do NOT want at runtime (lock down the image)
RUN apt-get update -q || true && \
    apt-get purge -y -q --auto-remove \
        openssh-client openssh-server \
        netcat-openbsd \
        net-tools \
        iputils-ping \
        telnet \
        traceroute \
        curl \
        wget \
        apt-utils || true && \
    dpkg --purge --force-all gpgv gnupg gnupg-utils || true; \
    dpkg --purge --force-all apt apt-utils || true; \
    rm -f /usr/bin/apt /usr/bin/apt-get /usr/bin/apt-cache /usr/bin/apt-config \
          /usr/bin/gpgv /usr/bin/gpg /usr/bin/gpgconf /usr/bin/gpg-agent || true; \
    rm -rf /etc/apt /var/lib/apt /var/cache/apt /var/lib/apt/lists/* /root/.gnupg || true; \
    rm -f /bin/apt /bin/apt-get /usr/local/bin/apt /usr/local/bin/apt-get || true

# Create directory for scripts
RUN mkdir -p /opt/wireguard

# Copy entrypoint script
COPY entrypoint.sh /opt/wireguard/entrypoint.sh
RUN chmod +x /opt/wireguard/entrypoint.sh

# Default environment
ENV WG_INTERFACE=wg0
ENV WG_CONFIG=/etc/wireguard/wg0.conf

WORKDIR /opt/wireguard

# We keep running as root because WireGuard needs NET_ADMIN
USER 0

ENTRYPOINT ["/opt/wireguard/entrypoint.sh"]
