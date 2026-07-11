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
    apt-get install -y kea-dhcp4-server kea-dhcp6-server libcap2-bin && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /usr/share/doc /usr/share/man /var/cache/*

# Grant file capabilities so Kea can run as non-root (uid 100 _kea) and still
# bind privileged ports (67/547) and open raw sockets. Kubernetes
# securityContext capability adds do NOT become effective for a non-root exec
# (the kernel clears the effective set on execve of a non-root process), so we
# bake the caps as file capabilities (permitted+effective, =ep) onto the
# binaries themselves. These xattrs survive the setuid-bit strip in the
# lockdown step below (chmod -s does not touch security.capability).
RUN setcap 'cap_net_bind_service,cap_net_raw,cap_net_admin=ep' /usr/sbin/kea-dhcp4 && \
    setcap 'cap_net_bind_service,cap_net_raw,cap_net_admin=ep' /usr/sbin/kea-dhcp6 && \
    getcap /usr/sbin/kea-dhcp4 /usr/sbin/kea-dhcp6

# Set environment variables
ENV LANG en_US.utf8
ENV TZ=Asia/Seoul

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

# Deep lockdown: minimize post-exploitation surface (nothing useful if the
# container is popped). Kea is a compiled binary and needs none of the below
# at runtime, so we remove interpreters, privilege-escalation vectors, extra
# shells, and strip every setuid/setgid bit image-wide.
RUN set -eu; \
    # remove language interpreters / powerful LOLBins
    dpkg --purge --force-all perl perl-base python3 python3-minimal || true; \
    rm -f /usr/bin/perl /usr/bin/perl5* /usr/bin/python3* \
          /usr/bin/awk /usr/bin/gawk /usr/bin/nawk /usr/bin/mawk || true; \
    # remove privilege-escalation / mount tooling
    rm -f /usr/bin/su /bin/su /usr/bin/sudo /usr/bin/newgrp /usr/bin/gpasswd \
          /usr/bin/passwd /usr/bin/chsh /usr/bin/chfn /usr/bin/expiry \
          /usr/bin/mount /usr/bin/umount /bin/mount /bin/umount \
          /usr/bin/wall /usr/bin/write || true; \
    # remove secondary interpreters/shells (keep bash for entrypoint + sh->dash for libc system())
    rm -f /usr/bin/tclsh* /usr/bin/lua* /usr/bin/zsh /usr/bin/ksh* || true; \
    # drop the capability-editing tools now that file caps are baked (xattrs persist)
    dpkg --purge --force-all libcap2-bin || true; \
    rm -f /sbin/setcap /sbin/getcap /usr/sbin/setcap /usr/sbin/getcap \
          /usr/bin/setcap /usr/bin/getcap || true; \
    # strip ALL setuid/setgid bits across the container filesystem layer
    find / -xdev -perm /6000 -type f -exec chmod -s '{}' + || true; \
    # clear temp/caches
    rm -rf /tmp/* /var/tmp/* /root/.cache || true

# Create necessary directories. The image user is _kea (uid 100, gid 101 on
# Ubuntu 24.04 Kea packages). Runtime PVCs are still handled by Kubernetes
# fsGroup, but these ownerships make the image work sanely without mounts too.
RUN mkdir -p /run/kea /var/lib/kea /etc/kea && \
    chown -R 100:101 /run/kea /var/lib/kea /etc/kea

# Copy startup script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Set volume mounts (mount these via PVC/ConfigMap in OKD)
VOLUME ["/etc/kea", "/var/lib/kea"]

ENTRYPOINT ["/entrypoint.sh"]
