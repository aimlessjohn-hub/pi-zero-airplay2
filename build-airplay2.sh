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
# ============================================================
set -euo pipefail

SRC_DIR="/usr/local/src"
NQPTP_REPO="https://github.com/mikebrady/nqptp.git"
SHAIRPORT_REPO="https://github.com/mikebrady/shairport-sync.git"
SHAIRPORT_TAG="5.0.4"

log() { echo "[+] $*"; }
err() { echo "[!] $*" >&2; exit 1; }

# Root-Check
[[ $EUID -eq 0 ]] || err "Dieses Skript muss als root ausgeführt werden (sudo)."

# Arch-Check
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
  avahi-daemon \
  build-essential \
  git \
  libavahi-client-dev \
  libconfig-dev \
  libdaemon-dev \
  libglib2.0-dev \
  libmosquitto-dev \
  libpopt-dev \
  libsdl2-dev \
  libsndfile1-dev \
  libsoxr-dev \
  libssl-dev \
  libtool \
  pkg-config \
  pulseaudio \
  xmltoman \
  xxd

log "Runtime-Dependencies installieren..."
apt install -y \
  libavahi-compat-libdnssd1 \
  libpulse0 \
  libsoxr0 \
  libssl3 \
  mosquitto

# ============================================================
# 2. nqptp bauen
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
# 3. Shairport-Sync bauen (AirPlay 2)
# ============================================================
log "Shairport-Sync $SHAIRPORT_TAG klonen..."
cd "$SRC_DIR"
[[ -d shairport-sync ]] && rm -rf shairport-sync
git clone --depth 1 --branch "$SHAIRPORT_TAG" "$SHAIRPORT_REPO"
cd shairport-sync

log "Shairport-Sync mit AirPlay-2-Support kompilieren..."
autoreconf -fi
./configure \
  --with-airplay-2 \
  --with-ssl=openssl \
  --with-avahi \
  --with-soxr \
  --with-systemd \
  --with-metadata \
  --with-mpris \
  --with-pipe \
  --with-pulseaudio
make -j$(nproc)
make install

# ============================================================
# 4. systemd-Dienste aktivieren
# ============================================================
log "nqptp-Dienst aktivieren..."
systemctl enable nqptp

log "Shairport-Sync-Dienst aktivieren..."
systemctl enable shairport-sync

# ============================================================
# 5. ALSA dmix vorbereiten (für parallelen DAC-Zugriff)
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
# 6. Fertig
# ============================================================
log "=== Build abgeschlossen ==="
log "nqptp:   $(nqptp --version 2>/dev/null || echo 'unbekannt')"
log "Shairport-Sync: $(shairport-sync -V 2>/dev/null || echo 'unbekannt')"
log ""
log "Jetzt Config anpassen:"
log "  sudo cp configs/shairport-sync.conf /etc/"
log "  sudo systemctl restart nqptp"
log "  sudo systemctl restart shairport-sync"
log ""
log "AirPlay 2 sollte unter 'PiZero-AirPlay2' (Port 7000) sichtbar sein."