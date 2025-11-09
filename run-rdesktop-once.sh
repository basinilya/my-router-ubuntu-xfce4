#!/usr/bin/env bash

#
# Connect to a locally running xrdp to start the GUI programs.
# Later you can connect to the same session with a regular RDP client.
#
# Usage:
#
#     RDP_USER="user1" RDP_PASS="s3cret" run-rdesktop-once.sh
#     or
#     CREDENTIALS_DIRECTORY=/some run-rdesktop-once.sh
#
# Normally is run as nobody as a systemd service.
# On success auth you'll see in system journal something like:
#     xrdp[55537]: [INFO ] connected ok
#

if [ -n "$CREDENTIALS_DIRECTORY" ] && cd -- "$CREDENTIALS_DIRECTORY"; then
  [ -n "$RDP_USER" ] || RDP_USER=$(< ./RDP_USER)
  [ -n "$RDP_PASS" ] || RDP_PASS=$(< ./RDP_PASS)
fi

# on first connect rdesktop will prompt for both the password and to accept the certificate
pass_and_yes="$RDP_PASS"$'\nyes\n'

set -euo pipefail

# Config: edit these
DISPLAY_NUM=99
RDESKTOP_BIN=/usr/bin/rdesktop    # change to /usr/bin/xfreerdp if you prefer
RDP_HOST="127.0.0.1"

RUN_SECONDS=30    # how long to keep the session alive

XVFB_BIN=/usr/bin/Xvfb
XVFB_SCREEN="0"
XVFB_GEOM="1024x768x24"

# Derived
export DISPLAY=":${DISPLAY_NUM}"

# Oct 26 14:28:03 sn-web-vpn systemd[1]: Started xrdp.service - xrdp daemon.
# Oct 26 14:28:04 sn-web-vpn xrdp[1053]: [INFO ] listening to port 3389 on 0.0.0.0
for ((i=0;i<20;i++)); do
  s=$(ss -Htln "sport 3389")
  [ -n "$s" ] && break
  echo nobody is listening on port 3389
  sleep 0.5
done

# Start Xvfb (background)
timeout --kill-after=3 $(("${RUN_SECONDS:?}" + 5)) "${XVFB_BIN}" "${DISPLAY}" -screen "${XVFB_SCREEN}" "${XVFB_GEOM}" &
XVFB_PID=$!

for ((i=0;i<20;i++)); do
  sleep 0.5   # give Xvfb a short moment
  xdpyinfo >/dev/null && break
done

# Start the RDP client (background)
# rdesktop invocation (example). For xfreerdp, replace accordingly:
#/usr/bin/xfreerdp /v:${RDP_HOST} /u:${RDP_USER} /p:${RDP_PASS} /size:1024x768 +clipboard /cert-ignore
timeout --kill-after=3 "${RUN_SECONDS:?}" "${RDESKTOP_BIN:?}" -u "${RDP_USER}" -p - -g "${XVFB_GEOM%*x*}" -r sound:remote "${RDP_HOST}" <<<"${pass_and_yes}" &
RDP_PID=$!

wait $RDP_PID || true
wait $XVFB_PID || true

exit 0
