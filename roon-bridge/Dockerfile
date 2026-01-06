FROM ubuntu:24.04

USER root

# Prevent interactive prompts during package installation
ARG DEBIAN_FRONTEND=noninteractive
ARG DISPLAY=localhost:0.0

# Build-time arch hint (used by buildx/buildah --arch)
ARG TARGETARCH

RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections
RUN dpkg-divert --local --rename --add /sbin/initctl
RUN ln -sf /bin/true /sbin/initctl
RUN echo "#!/bin/sh\nexit 0" > /usr/sbin/policy-rc.d

# Install necessary packages for RoonBridge and audio/network support
RUN apt-get update -q && \
    apt-get install --no-install-recommends -y -q \
        ca-certificates \
        ffmpeg \
        libasound2t64 \
        alsa-utils \
        libicu-dev \
        curl \
        wget \
        bzip2 \
        lbzip2 \
        tzdata \
        locales && \
    apt-get autoremove -y -q && \
    apt-get clean -y -q && \
    rm -rf /var/lib/apt/lists/* /usr/share/doc /usr/share/man /var/cache/* && \
    localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8

# Set environment variables
ENV LANG=en_US.utf8
ENV TZ=Asia/Seoul
ENV HOME=/opt/RoonBridge
ENV ROON_DATAROOT=/var/roon
ENV ROON_ID_DIR=/var/roon

# Configure timezone
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && \
    echo $TZ > /etc/timezone

# Download and extract RoonBridge to /opt (choose artifact by arch)
WORKDIR /opt
RUN set -e; \
    arch="${TARGETARCH:-}"; \
    if [ -z "$arch" ]; then \
      arch="$(dpkg --print-architecture)"; \
      case "$arch" in \
        amd64) arch="amd64" ;; \
        arm64) arch="arm64" ;; \
      esac; \
    fi; \
    case "$arch" in \
      amd64)  pkg="RoonBridge_linuxx64.tar.bz2" ;; \
      arm64)  pkg="RoonBridge_linuxarmv8.tar.bz2" ;; \
      *) echo "Unsupported architecture: $arch" >&2; exit 1 ;; \
    esac; \
    echo "Downloading $pkg for arch=$arch"; \
    wget -nv "https://download.roonlabs.com/builds/${pkg}" -O "/opt/${pkg}"; \
    bzip2 -d "/opt/${pkg}"; \
    tar -xvf "/opt/${pkg%.bz2}"; \
    rm -f "/opt/${pkg%.bz2}"

# After RoonBridge is installed, remove apt and tools (keep minimal runtime)
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

# Create directory
RUN mkdir -p /var/roon

# Declare mountable volumes
VOLUME ["/opt/RoonBridge", "/var/roon"]

# Set working directory
WORKDIR /opt/RoonBridge

# Default command to launch RoonBridge
CMD ["/opt/RoonBridge/start.sh"]
