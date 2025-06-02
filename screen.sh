#!/usr/bin/env bash
#
# screen.sh — fullscreen Chromium kiosk that refreshes automatically
#             (waits 30 s before doing anything so the Pi can finish booting)
#
# Quick edit: change the refresh interval here ↓
REFRESH_SECS=3600          # seconds between reloads
# ------------------------------------------------------------------

set -euo pipefail
URL=${1:-""}
export DISPLAY=:0         # X11 or XWayland

# --- Give the system 30 s to settle --------------------------------
sleep 30

# --- Hide cursor if possible ---------------------------------------
command -v unclutter-xfixes >/dev/null && unclutter-xfixes --idle 0 --root &

# --- Launch Chromium in X11 kiosk mode -----------------------------
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

# --- Wait for the window so xdotool can target it ------------------
for _ in {1..30}; do
  CHROME_WID=$(xdotool search --sync --onlyvisible --pid "$BROWSER_PID" 2>/dev/null | head -n1 || true)
  [[ -n "$CHROME_WID" ]] && break
  sleep 1
done
[[ -z "${CHROME_WID:-}" ]] && { echo "Could not find Chromium window"; exit 1; }

echo "✅  Refreshing every ${REFRESH_SECS}s (window $CHROME_WID)"

# --- Hard-refresh the window every REFRESH_SECS seconds ------------
while kill -0 "$BROWSER_PID" 2>/dev/null; do
  sleep "$REFRESH_SECS"
  xdotool key --window "$CHROME_WID" --clearmodifiers F5
done
