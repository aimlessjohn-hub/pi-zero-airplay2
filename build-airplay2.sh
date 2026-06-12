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
#   - GitHub Actions (ubuntu-24.04-arm)
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
  --with-airplay-2 \
  --with-ssl=openssl \
  --with-avahi \
  --with-soxr \
  --with-metadata \
  --with-pipe
make -j$(nproc)
make install

# ============================================================
# 5. systemd-Dienste aktivieren
# ============================================================
log "nqptp-Dienst aktivieren..."
systemctl enable nqptp

log "Shairport-Sync-Dienst aktivieren..."
systemctl enable shairport-sync

# ============================================================
# 6. ALSA dmix vorbereiten
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
# 7. Fertig
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