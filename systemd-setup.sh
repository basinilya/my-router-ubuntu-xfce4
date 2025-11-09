#!/bin/bash

# Ubuntu's /bin/sh doesn't support pipefail
# Therefore a separate bash script is needed
set -euo pipefail

set -x

# by this time systemd should be installed, but not running

echo "Disabling persistent journal"
sed -i 's/^#*Storage=.*/Storage=volatile/' /etc/systemd/journald.conf
# grep '^#*Storage=' /etc/systemd/journald.conf

echo "Disabling services irrelevant in docker"
# rtkit-daemon[420]: --cap-add cap_sys_nice only works when container run as root
# cap_set_proc() failed: Operation not permitted
# https://github.com/moby/moby/issues/50083
systemctl mask rtkit-daemon.service
systemctl mask tpm-udev.service
systemctl mask gdm.service
systemctl mask getty@tty1.service
systemctl set-default multi-user.target

echo "Adding graphical user"
useradd -m user1 -s /bin/bash

# TODO move this to a later stage
# create encrypted credentials for RDP login
echo "user1" | systemd-creds encrypt --name=RDP_USER - /etc/credstore.encrypted/run-rdesktop-once-user.cred
# mind that set -x makes shell variables with the password visible in the build logs
</dev/random head -c16 | base64 | systemd-creds encrypt --name=RDP_PASS - /etc/credstore.encrypted/run-rdesktop-once-pass.cred
echo "Setting graphical user password from encrypted credential store"
( printf "user1:"; systemd-creds decrypt --name=RDP_PASS /etc/credstore.encrypted/run-rdesktop-once-pass.cred ) | chpasswd

# password isn't needed yet
#echo user1:123 | chpasswd user1
#( printf user1:; dd status=none bs=1 if=/dev/random count=16 | base64 ) | chpasswd user1

echo "Setting default desktop environment"
cat <<'EOF' | sudo -u user1 sh -c 'cat >~/.xsessionrc'
export STARTUP=xfce4-session
export XDG_CONFIG_DIRS=/etc/xdg
EOF

install -Dm755 /var/tmp/my-router-ubuntu-xfce4-install/run-rdesktop-once.sh /usr/local/bin/run-rdesktop-once.sh
install -Dm644 /var/tmp/my-router-ubuntu-xfce4-install/rdesktop-once.service /etc/systemd/system/rdesktop-once.service
systemctl enable rdesktop-once.service