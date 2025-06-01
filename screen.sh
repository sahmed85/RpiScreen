#!/usr/bin/env bash
#
# kiosk-refresh.sh  —  Full-screen Chromium kiosk.
#                     Refreshes the page every $REFRESH_SECS seconds.
#
# Quick edit: set the refresh interval here ⬇
REFRESH_SECS=10          # ← change to 30, 60, 600, … as required
# ------------------------------------------------------------------
# Usage examples
#   ./kiosk-refresh.sh
#   ./kiosk-refresh.sh https://darussalammasjidatl.org/prayer-time/

set -euo pipefail
URL=${1:-""}
export DISPLAY=:0        # X11 or XWayland

# Hide cursor (if unclutter-xfixes is installed)
command -v unclutter-xfixes >/dev/null && unclutter-xfixes --idle 0 --root &

# Launch Chromium in X11 kiosk mode, minimal logging
chromium-browser \
  --ozone-platform=x11 \
  --kiosk \
  --hide-scrollbars \
  --incognito \
  --noerrdialogs \
  --disable-infobars \
  --disable-session-crashed-bubble \
  --log-level=3 \
  ${URL:+ "$URL"} &
BROWSER_PID=$!

# Wait until Chromium’s first window is visible and grab its WID
for _ in {1..30}; do
  CHROME_WID=$(xdotool search --sync --onlyvisible --pid "$BROWSER_PID" 2>/dev/null | head -n1 || true)
  [[ -n "$CHROME_WID" ]] && break
  sleep 1
done
[[ -z "${CHROME_WID:-}" ]] && { echo "Could not find Chromium window"; exit 1; }

echo "✅  Refreshing every ${REFRESH_SECS}s (window $CHROME_WID)"

# Hard-refresh the window every REFRESH_SECS seconds
while kill -0 "$BROWSER_PID" 2>/dev/null; do
  sleep "$REFRESH_SECS"
  xdotool key --window "$CHROME_WID" --clearmodifiers F5
done
