# Raspberry Pi Kiosk

> **Self‑refreshing fullscreen kiosk for Raspberry Pi 3 running Raspberry Pi OS (Bookworm/Bullseye).**
> *Shows any URL you choose (e.g. `https://<YOUR_URL_HERE>`), reloading on an interval you set.*

---

## Features

* **Fullscreen Chromium kiosk** – no toolbars, no scroll‑bar, no mouse cursor.
* **Configurable auto‑refresh** (edit `REFRESH_SECS` at the top of `screen.sh`).
* Works under **X11** *or* Wayland (Chromium is forced to X11 with `--ozone-platform=x11`).
* **Noise‑free logs** – suppresses routine Chromium SSL chatter.
* Simple **systemd service** for automatic start & restart on crash.

---

## Hardware & OS

| Component                               | Tested ✓ |
| --------------------------------------- | -------- |
| Raspberry Pi 3B / 3B+                   | ✔︎       |
| Raspberry Pi OS Bookworm 32‑bit desktop | ✔︎       |
| Raspberry Pi OS Bullseye 32‑bit desktop | ✔︎       |
| HDMI monitor @ 1080p                    | ✔︎       |

> Should run on any Pi capable of Chromium, but performance below Pi 3 may vary.

---

## Quick Start

1. **Update & install packages**

   ```bash
   sudo apt update && sudo apt full-upgrade -y && sudo reboot
   sudo apt install -y chromium-browser xdotool unclutter-xfixes curl ca-certificates
   # (Package name is just "chromium" on Bookworm.)
   ```
2. **Verify time sync** (TLS handshakes will fail if the clock is wrong):

   ```bash
   timedatectl status   # look for "System clock synchronized: yes"
   ```
3. *(Optional)* **Switch the desktop session to X11** for slightly lower CPU and cleaner logs:

   ```bash
   sudo raspi-config          # 6 Advanced → A6 Wayland → W1 X11 (Legacy)
   sudo reboot
   ```
4. **Configure your kiosk script** — the repo already includes **`screen.sh`**.

   * Open the file and set `REFRESH_SECS` and the default URL if you wish.
   * Make it executable:  `chmod +x screen.sh`.
5. **Manual test**

   ```bash
   ./screen.sh https://<YOUR_URL_HERE>
   ```

   You should see a full‑screen page with hidden cursor/scroll‑bar refreshing every `REFRESH_SECS` seconds.

---

## Autostart with systemd

Create a unit file:

```bash
sudo nano /etc/systemd/system/kiosk.service
```

```ini
[Unit]
Description=Chromium Kiosk (auto‑refresh)
After=graphical.target network-online.target
Wants=network-online.target

[Service]
Environment=DISPLAY=:0
Type=simple
ExecStart=/home/pi/screen.sh https://<YOUR_URL_HERE>
Restart=on-failure
RestartSec=5

[Install]
WantedBy=graphical.target
```

Enable and start:

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now kiosk.service
```

Reboot—your Pi should land directly in the kiosk.

### Managing the service

```bash
sudo systemctl stop kiosk.service        # stop once
sudo systemctl disable kiosk.service     # remove from startup
journalctl -u kiosk.service -f           # live logs
```

---

## Troubleshooting

| Symptom                                  | Likely cause                                    | Fix                                                                                           |
| ---------------------------------------- | ----------------------------------------------- | --------------------------------------------------------------------------------------------- |
| "Site can’t be reached" on boot          | Pi came up before Wi‑Fi.                        | Ensure credentials in `wpa_supplicant.conf`; the script retries every `REFRESH_SECS` seconds. |
| `handshake failed; SSL error` in console | Wrong clock or captive portal intercepting TLS. | Check `timedatectl`; update CA bundle via `sudo apt install --reinstall ca-certificates`.     |
| Cursor visible                           | `unclutter-xfixes` not installed.               | `sudo apt install unclutter-xfixes`                                                           |
| Need slower refresh                      | Edit `REFRESH_SECS` in `screen.sh`.             |                                                                                               |

---

## Roadmap / ideas

* Add a DS3231 RTC to retain time without Internet.
* Use Anthias (Screenly OSE) when managing multiple kiosks.

---

## License

MIT © 2025 – fork away.
