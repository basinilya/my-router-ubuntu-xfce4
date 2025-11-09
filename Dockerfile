# Usage:
#   docker build -t my-router-ubuntu-xfce4-pre .
#
#       docker run --rm -t \
#         --privileged \
#         --cgroup-parent=docker.slice --cgroupns private \
#         --name systemd_test3 \
#         --entrypoint /bin/bash \
#         -p 2225:3389 \
#         --cap-add cap_net_admin \
#         --cap-add cap_net_bind_service \
#         --cap-add cap_net_raw \
#         --cap-add cap_sys_nice \
#         --cap-add cap_sys_time \
#         --cap-add cap_sys_resource \
#         --cap-add SYS_PTRACE \
#         --cap-add SYS_ADMIN --security-opt seccomp=unconfined \
#         my-router-ubuntu-xfce4-pre \
#         -c "mount --make-rshared / && exec /lib/systemd/systemd log-level=info unit=sysinit.target"
#
# Optionally prepend /lib/systemd/systemd with: /usr/bin/strace -f --daemonize
# You can also prefix the whole command with: umount /dev/shm && 
# (but that doesn't make any difference)
#
# To open a shell do in another terminal: 
#      docker exec -it systemd_test3 bash

FROM ubuntu:latest

# avoid some interactive post-install configuration dialogs
ARG DEBIAN_FRONTEND=noninteractive

# Suboptimal but make troubleshooting easier

# do not erase .deb files after installation
RUN \
  --mount=type=tmpfs,target=/tmp \
  --mount=type=tmpfs,target=/run \
  --mount=type=tmpfs,target=/run/lock \
  --mount=type=cache,target=/var/cache/apt/archives,sharing=locked,id=my-router-ubuntu-xfce4-var-cache-apt-archives \
  --mount=type=cache,target=/var/lib/apt/lists,sharing=locked,id=my-router-ubuntu-xfce4-var-lib-apt-lists \
  mv -T /etc/apt/apt.conf.d/docker-clean /etc/apt/apt.conf.d-docker-clean.save || true

# update and upgrade 
RUN \
  --mount=type=tmpfs,target=/tmp \
  --mount=type=tmpfs,target=/run \
  --mount=type=tmpfs,target=/run/lock \
  --mount=type=cache,target=/var/cache/apt/archives,sharing=locked,id=my-router-ubuntu-xfce4-var-cache-apt-archives \
  --mount=type=cache,target=/var/lib/apt/lists,sharing=locked,id=my-router-ubuntu-xfce4-var-lib-apt-lists \
  apt-get -y update && apt-get -y upgrade

# for network
RUN \
  --mount=type=tmpfs,target=/tmp \
  --mount=type=tmpfs,target=/run \
  --mount=type=tmpfs,target=/run/lock \
  --mount=type=cache,target=/var/cache/apt/archives,sharing=locked,id=my-router-ubuntu-xfce4-var-cache-apt-archives \
  --mount=type=cache,target=/var/lib/apt/lists,sharing=locked,id=my-router-ubuntu-xfce4-var-lib-apt-lists \
  apt-get install -y --no-install-recommends sudo iproute2 iptables iputils-ping dnsutils winpr-utils xz-utils curl ca-certificates

# install XFCE4 desktop environment
RUN \
  --mount=type=tmpfs,target=/tmp \
  --mount=type=tmpfs,target=/run \
  --mount=type=tmpfs,target=/run/lock \
  --mount=type=cache,target=/var/cache/apt/archives,sharing=locked,id=my-router-ubuntu-xfce4-var-cache-apt-archives \
  --mount=type=cache,target=/var/lib/apt/lists,sharing=locked,id=my-router-ubuntu-xfce4-var-lib-apt-lists \
  apt-get install -y --no-install-recommends xfce4 xfce4-notifyd xfce4-terminal x11-utils netfilter-persistent

# install xrdp for remote desktop access
RUN \
  --mount=type=tmpfs,target=/tmp \
  --mount=type=tmpfs,target=/run \
  --mount=type=tmpfs,target=/run/lock \
  --mount=type=cache,target=/var/cache/apt/archives,sharing=locked,id=my-router-ubuntu-xfce4-var-cache-apt-archives \
  --mount=type=cache,target=/var/lib/apt/lists,sharing=locked,id=my-router-ubuntu-xfce4-var-lib-apt-lists \
  apt-get install -y --no-install-recommends xrdp xorgxrdp && \
  echo "fixing /etc/xrdp/key.pem: Permission denied" && \
  adduser xrdp ssl-cert

# install rdesktop and fake X server to run it headless
RUN \
  --mount=type=tmpfs,target=/tmp \
  --mount=type=tmpfs,target=/run \
  --mount=type=tmpfs,target=/run/lock \
  --mount=type=cache,target=/var/cache/apt/archives,sharing=locked,id=my-router-ubuntu-xfce4-var-cache-apt-archives \
  --mount=type=cache,target=/var/lib/apt/lists,sharing=locked,id=my-router-ubuntu-xfce4-var-lib-apt-lists \
  apt-get install -y --no-install-recommends xvfb rdesktop

# troubleshooting tools
RUN \
  --mount=type=tmpfs,target=/tmp \
  --mount=type=tmpfs,target=/run \
  --mount=type=tmpfs,target=/run/lock \
  --mount=type=cache,target=/var/cache/apt/archives,sharing=locked,id=my-router-ubuntu-xfce4-var-cache-apt-archives \
  --mount=type=cache,target=/var/lib/apt/lists,sharing=locked,id=my-router-ubuntu-xfce4-var-lib-apt-lists \
  apt-get install -y --no-install-recommends traceroute screen tcpdump less vim strace lsof

# setup systemd services and graphical user
RUN \
  --mount=type=tmpfs,target=/tmp \
  --mount=type=tmpfs,target=/run \
  --mount=type=tmpfs,target=/run/lock \
  --mount=type=cache,target=/var/cache/apt/archives,sharing=locked,id=my-router-ubuntu-xfce4-var-cache-apt-archives \
  --mount=type=cache,target=/var/lib/apt/lists,sharing=locked,id=my-router-ubuntu-xfce4-var-lib-apt-lists \
  --mount=type=bind,target=/var/tmp/my-router-ubuntu-xfce4-install \
  [ "/bin/bash", "/var/tmp/my-router-ubuntu-xfce4-install/systemd-setup.sh" ]

# install Firefox in /opt (not the containerized Firefox)
RUN \
  --mount=type=tmpfs,target=/tmp \
  --mount=type=tmpfs,target=/run \
  --mount=type=tmpfs,target=/run/lock \
  --mount=type=cache,target=/var/cache/apt/archives,sharing=locked,id=my-router-ubuntu-xfce4-var-cache-apt-archives \
  --mount=type=cache,target=/var/lib/apt/lists,sharing=locked,id=my-router-ubuntu-xfce4-var-lib-apt-lists \
  --mount=type=bind,target=/var/tmp/my-router-ubuntu-xfce4-install \
  --mount=type=cache,target=/var/cache/my-downloads,sharing=locked,id=my-downloads \
  cd /var/cache/my-downloads && \
  curl -f -O --remote-time --time-cond "./firefox-143.0.4.tar.xz" "https://download-installer.cdn.mozilla.net/pub/firefox/releases/143.0.4/linux-x86_64/en-US/firefox-143.0.4.tar.xz" && \
  cd /opt && \
  tar -xf /var/cache/my-downloads/firefox-143.0.4.tar.xz && \
  install -Dm644 /var/tmp/my-router-ubuntu-xfce4-install/opt-firefox.desktop /usr/share/applications/opt-firefox.desktop && \
  update-desktop-database
