#!/usr/bin/env bash
# ============================================================
# build-airplay2.sh – AirPlay 2 auf Raspberry Pi Zero 2 W
#
# Kompiliert nqptp + Shairport-Sync 5 aus dem Quellcode
# für AirPlay 2 auf ARM64 (Pi Zero 2 / Pi 3/4/5).
#
# Nutzung:
#   chmod +x build-airplay2.sh
#   sudo ./build-airplay2.sh
#
# Getestet auf:
#   - Raspberry Pi OS Lite (64-bit, Bookworm)
#   - Debian 13 Trixie (arm64)
#   - Pi Zero 2 W (416 MB RAM)
#
# Bekannte Issues und Workarounds:
#   - Apple USB-C DAC: SPS_FORMAT-Crash → disable_standby_mode = "never"
#   - nqptp Port 319: CAP_NET_BIND_SERVICE erforderlich
#   - apt-mark hold shairport-sync verhindert Überschreiben durch apt
# ============================================================
set -euo pipefail

SRC_DIR="/usr/local/src"
NQPTP_REPO="https://github.com/mikebrady/nqptp.git"
SHAIRPORT_REPO="https://github.com/mikebrady/shairport-sync.git"
SHAIRPORT_TAG="5.0.4"
ALAC_REPO="https://github.com/mikebrady/alac.git"

log() { echo "[+] $*"; }
err() { echo "[!] $*" >&2; exit 1; }

[[ $EUID -eq 0 ]] || err "Dieses Skript muss als root ausgeführt werden (sudo)."

ARCH=$(uname -m)
case "$ARCH" in
  aarch64|armv7l) log "Architektur: $ARCH ✓" ;;
  *) err "Nicht unterstützte Architektur: $ARCH (nur arm64/armv7l)" ;;
esac

# ============================================================
# 1. Systemaktualisierung & Dependencies
# ============================================================
log "Systemaktualisierung..."
apt update && apt upgrade -y

log "Build-Dependencies installieren..."
apt install -y \
  autoconf \
  automake \
  build-essential \
  cmake \
  git \
  libavahi-client-dev \
  libavcodec-dev \
  libavformat-dev \
  libavutil-dev \
  libconfig-dev \
  libdaemon-dev \
  libgcrypt-dev \
  libglib2.0-dev \
  libmosquitto-dev \
  libplist-dev \
  libpopt-dev \
  libsndfile1-dev \
  libsodium-dev \
  libsoxr-dev \
  libssl-dev \
  libsystemd-dev \
  libtool \
  pkg-config \
  uuid-dev \
  xmltoman \
  xxd

log "Runtime-Dependencies installieren..."
apt install -y \
  libavahi-compat-libdnssd1 \
  libplist-utils \
  libpulse0 \
  libsoxr0 \
  libssl3 \
  mosquitto

# ============================================================
# 2. ALAC (Apple Lossless Audio Codec) bauen
# ============================================================
log "ALAC klonen..."
cd "$SRC_DIR"
[[ -d alac ]] && rm -rf alac
git clone --depth 1 "$ALAC_REPO"
cd alac

log "ALAC kompilieren..."
cmake . -DCMAKE_BUILD_TYPE=Release
make -j$(nproc)
make install
ldconfig

# ============================================================
# 3. nqptp bauen
# ============================================================
log "nqptp klonen..."
cd "$SRC_DIR"
[[ -d nqptp ]] && rm -rf nqptp
git clone --depth 1 "$NQPTP_REPO"
cd nqptp

log "nqptp kompilieren..."
autoreconf -fi
./configure --with-systemd-startup
make -j$(nproc)
make install

# ============================================================
# 4. Shairport-Sync bauen (AirPlay 2)
# ============================================================
log "Shairport-Sync $SHAIRPORT_TAG klonen..."
cd "$SRC_DIR"
[[ -d shairport-sync ]] && rm -rf shairport-sync
git clone --depth 1 --branch "$SHAIRPORT_TAG" "$SHAIRPORT_REPO"
cd shairport-sync

log "Shairport-Sync mit AirPlay-2-Support kompilieren..."
autoreconf -fi
./configure \
  --sysconfdir=/etc \
  --with-airplay-2 \
  --with-ssl=openssl \
  --with-avahi \
  --with-soxr \
  --with-alsa \
  --with-metadata \
  --with-pipe \
  --with-dbus-interface \
  --with-mpris-interface
make -j$(nproc)
make install

# apt-mark hold: verhindert Überschreiben durch apt upgrade/install
apt-mark hold shairport-sync 2>/dev/null && log "shairport-sync via apt-mark held" || true

# ============================================================
# 5. nqptp Service mit Capabilities für Port 319
# ============================================================
log "nqptp-Service mit CAP_NET_BIND_SERVICE installieren..."
cat > /etc/systemd/system/nqptp.service << 'ENQPTP'
[Unit]
Description=Network Quality of Service Precision Time Protocol (nqptp)
Documentation=man:nqptp(1)
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=/usr/local/bin/nqptp
Restart=on-failure
RestartSec=5
AmbientCapabilities=CAP_SYS_TIME CAP_NET_BIND_SERVICE CAP_NET_RAW
CapabilityBoundingSet=CAP_SYS_TIME CAP_NET_BIND_SERVICE CAP_NET_RAW
ProtectSystem=full
ProtectHome=yes
PrivateTmp=yes
MemoryDenyWriteExecute=yes
NoNewPrivileges=yes

[Install]
WantedBy=multi-user.target
ENQPTP

systemctl daemon-reload
systemctl enable nqptp

# ============================================================
# 6. Shairport-Sync Service
# ============================================================
log "Shairport-Sync-Service installieren..."
systemctl enable shairport-sync

# ============================================================
# 7. ALSA dmix vorbereiten
# ============================================================
if [[ ! -f /etc/asound.conf ]]; then
  log "ALSA dmix-Konfiguration schreiben..."
  cat > /etc/asound.conf << 'EASOUND'
pcm.!default {
    type dmix
    slave {
        pcm "hw:0"
        period_time 0
        period_size 1024
        buffer_size 4096
        rate 48000
    }
    bindings {
        0 0
        1 1
    }
}

ctl.!default {
    type hw
    card 0
}
EASOUND
fi

# ============================================================
# 8. Hardware-Volume sichern (Apple USB-C DAC 100%)
# ============================================================
log "Hardware-Volume auf 100% setzen und sichern..."
amixer -c 0 sset Headphone 120 2>/dev/null || true
alsactl store 2>/dev/null || true

# systemd-Service für Boot-Sicherung
cat > /etc/systemd/system/alsa-headphone-volume.service << 'EVOL'
[Unit]
Description=Setze Apple USB-C DAC Headphone Lautstärke auf 100% (0dB)
After=alsa-restore.service sound.target
Requires=alsa-restore.service

[Service]
Type=oneshot
ExecStart=/usr/bin/amixer -c 0 sset Headphone 120
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EVOL

systemctl daemon-reload
systemctl enable alsa-headphone-volume.service

# ============================================================
# 9. Fertig
# ============================================================
log "=== Build abgeschlossen ==="
log "nqptp:   $(nqptp --version 2>/dev/null || echo 'unbekannt')"
log "Shairport-Sync: $(shairport-sync -V 2>/dev/null | head -1 || echo 'unbekannt')"
log ""
log "Jetzt Config anpassen:"
log "  sudo cp configs/shairport-sync.conf /etc/"
log "  sudo systemctl restart nqptp"
log "  sudo systemctl restart shairport-sync"
log ""
log "AirPlay 2 sollte unter 'PiZero-AirPlay2' (Port 7000) sichtbar sein."
log ""
log "⚠ Wichtige Workarounds in der Config:"
log "  - disable_standby_mode = \"never\" (SPS_FORMAT-Crash mit Apple DAC)"
log "  - output_format = \"S16_LE\" + output_rate = 48000"
log "  - mdns = \"avahi\" (sonst kein mDNS-Announce)"