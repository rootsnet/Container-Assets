FROM ubuntu:24.04

USER root

# Prevent interactive prompts during package installation
ARG DEBIAN_FRONTEND=noninteractive
ARG DISPLAY=localhost:0.0
RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections
RUN dpkg-divert --local --rename --add /sbin/initctl
RUN ln -sf /bin/true /sbin/initctl
RUN echo "#!/bin/sh\nexit 0" > /usr/sbin/policy-rc.d

RUN apt-get update && \
    apt-get install -y isc-dhcp-server && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Set environment variables
ENV LANG en_US.utf8
ENV TZ=Asia/Seoul

# Create necessary directories
RUN mkdir -p /run/dhcp-server /var/lib/dhcp && \
    chown root:dhcpd /var/lib/dhcp && \
    chmod 775 /var/lib/dhcp

# Create empty leases file with correct permissions
RUN touch /var/lib/dhcp/dhcpd.leases && \
    chown root:dhcpd /var/lib/dhcp/dhcpd.leases && \
    chmod 664 /var/lib/dhcp/dhcpd.leases

# Copy startup script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Set volume mounts (you will mount these via PVC or ConfigMap in OKD)
VOLUME ["/etc/dhcp", "/var/lib/dhcp"]

ENTRYPOINT ["/entrypoint.sh"]
