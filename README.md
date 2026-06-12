# pi-zero-airplay2 🇩🇪 🇬🇧

> **AirPlay 2 auf dem Raspberry Pi Zero 2 W — selbst kompiliert, optimiert, reproduzierbar.**
> *AirPlay 2 on the Raspberry Pi Zero 2 W — self-compiled, optimized, reproducible.*

---

## Features

### 🇩🇪
- ✅ **AirPlay 2** – synchron mit HomePods, Apple TV, Libratone etc. (nqptp + Shairport-Sync 5)
- ✅ **AirPlay 1 Fallback** – ältere Geräte streamen trotzdem
- ✅ **Nextcloud-Subsonic** – eigene Musik via Mopidy + Subidy
- ✅ **Internetradio** – M3U-Playlisten, läuft parallel
- ✅ **Parallele Ausgabe** – AirPlay + Mopidy gleichzeitig (ALSA dmix)
- ✅ **Auto-Pause** – AirPlay pausiert Mopidy, Resume nach Ende
- ✅ **Hardware-Volume** – Apple USB-C DAC, Lautstärke pro Dienst getrennt
- ✅ **Geringer Footprint** – ~220 MB RAM nach AirPlay 2 Start
- ✅ **GitHub Actions** – automatische ARM64-Builds, keine Cross-Compile nötig
- ✅ **Pre-built Binaries** – Download im Release-Tab, kein Build nötig

### 🇬🇧
- ✅ **AirPlay 2** – synchronized with HomePods, Apple TV, Libratone (nqptp + Shairport-Sync 5)
- ✅ **AirPlay 1 fallback** – older devices still work
- ✅ **Nextcloud Subsonic** – your own music via Mopidy + Subidy
- ✅ **Internet radio** – M3U playlists, runs in parallel
- ✅ **Parallel output** – AirPlay + Mopidy simultaneously (ALSA dmix)
- ✅ **Auto-pause** – AirPlay pauses Mopidy, resumes after playback ends
- ✅ **Hardware volume** – Apple USB-C DAC, per-service volume control
- ✅ **Low footprint** – ~220 MB RAM after AirPlay 2 starts
- ✅ **GitHub Actions** – automated ARM64 builds, no cross-compile needed
- ✅ **Pre-built binaries** – download from Releases tab, no build required

---

## Repository Structure / Verzeichnisstruktur

```
pi-zero-airplay2/
├── README.md                  # 🇩🇪🇬🇧 This file
├── LICENSE                    # GPL-3.0
├── build-airplay2.sh          # 🇩🇪 Build script for AirPlay 2 on Pi Zero 2
│                              # 🇬🇧 (English comments inside)
├── configs/
│   ├── shairport-sync.conf    # AirPlay 2 configuration
│   ├── nqptp.service          # systemd service for nqptp (PTP sync)
│   ├── shairport-sync.service # systemd service for Shairport-Sync
│   ├── asound.conf            # ALSA dmix for shared DAC access
│   ├── mopidy.conf            # Mopidy config (Subsonic + radio)
│   └── airplay-mopidy.sh      # 🇩🇪 Pause/resume on AirPlay
└── .github/workflows/
    └── build.yml              # GitHub Actions (ARM64 builds)
```

---

## Quick Start 🇩🇪

### 1. Voraussetzungen

- Raspberry Pi Zero 2 W mit **Raspberry Pi OS Lite (64-bit)** oder **Debian 13 (Trixie) arm64**
- USB-DAC (z. B. Apple USB-C Headphone Adapter)
- Internetzugang (WLAN oder Ethernet via OTG)
- SSH-Zugriff
- **Oder:** [Pre-built Binaries herunterladen](#pre-built-binaries-) und Schritt 2 überspringen

### 2. Build-Skript ausführen (nur bei Selbstbau)

```bash
chmod +x build-airplay2.sh
sudo ./build-airplay2.sh
```

Das Skript installiert alle Dependencies, kompiliert **nqptp** und **Shairport-Sync 5** aus dem Quellcode, konfiguriert systemd und ALSA.

### 3. Konfiguration anpassen

```bash
# Configs nach /etc kopieren
sudo cp configs/shairport-sync.conf /etc/
sudo cp configs/nqptp.service /etc/systemd/system/
sudo cp configs/shairport-sync.service /etc/systemd/system/
sudo cp configs/asound.conf /etc/
sudo systemctl daemon-reload

# Dienste starten
sudo systemctl enable --now nqptp
sudo systemctl enable --now shairport-sync
```

### 4. Fertig

AirPlay 2 streamt auf **"PiZero-AirPlay2"** (Port 7000). Apple-Geräte in Reichweite finden den Lautsprecher automatisch.

---

## Quick Start 🇬🇧

### 1. Prerequisites

- Raspberry Pi Zero 2 W with **Raspberry Pi OS Lite (64-bit)** or **Debian 13 (Trixie) arm64**
- USB DAC (e.g. Apple USB-C Headphone Adapter)
- Network access (WiFi or Ethernet via OTG)
- SSH access
- **Or:** [Download pre-built binaries](#pre-built-binaries-) and skip step 2

### 2. Build (only if building from source)

```bash
chmod +x build-airplay2.sh
sudo ./build-airplay2.sh
```

The script installs all dependencies, compiles **nqptp** and **Shairport-Sync 5** from source, and configures systemd and ALSA.

### 3. Apply configuration

```bash
sudo cp configs/shairport-sync.conf /etc/
sudo cp configs/nqptp.service /etc/systemd/system/
sudo cp configs/shairport-sync.service /etc/systemd/system/
sudo cp configs/asound.conf /etc/
sudo systemctl daemon-reload

sudo systemctl enable --now nqptp
sudo systemctl enable --now shairport-sync
```

### 4. Done

AirPlay 2 will stream on **"PiZero-AirPlay2"** (port 7000). Apple devices on your network will find the speaker automatically.

---

## Background / Hintergrund 🇬🇧

The Pi Zero 2 W only has **512 MB RAM** and a Quad-Core **Cortex-A53** at 1 GHz. Official Shairport-Sync packages from `apt` only provide AirPlay 1. AirPlay 2 requires:

1. **nqptp** – Network Quality of Service Precision Time Protocol (PTP synchronisation)
2. **Shairport-Sync ≥ 4.0** with `--with-airplay-2` flag

Both must be **compiled from source code**. The build script in this repo does exactly that — reproducible and documented.

### Why not piCorePlayer / moOde / Lyrion?

- **piCorePlayer**: Squeezelite only, no native AirPlay 2
- **moOde**: Has AirPlay 2 built-in, but uses ~300 MB RAM — too much for Pi Zero 2
- **Lyrion/LMS**: Overkill for a single room; better as a server on Proxmox

### What runs in parallel on the Pi Zero 2?

Thanks to **ALSA dmix**, AirPlay 2 + Mopidy (Subsonic client) run simultaneously:

- **AirPlay 2** from iPhone/Mac (iPhone volume control)
- **Subsonic/Subidy** for your Nextcloud music library
- **Internet radio** from M3U playlists (via Mopidy)

## Hintergrund 🇩🇪

Der Pi Zero 2 W hat nur **512 MB RAM** und einen Quad-Core **Cortex-A53** bei 1 GHz. Offizielle Shairport-Sync-Pakete aus `apt` gibt es nur als AirPlay 1. AirPlay 2 benötigt:

1. **nqptp** – Network Quality of Service Precision Time Protocol (PTP-Synchronisation)
2. **Shairport-Sync ≥ 4.0** mit `--with-airplay-2` Flag

Beide müssen **aus dem Quellcode kompiliert werden**. Das Build-Skript in diesem Repo macht genau das – reproduzierbar und dokumentiert.

### Warum kein piCorePlayer / moOde / Lyrion?

- **piCorePlayer**: Läuft nur als Squeezelite, kein AirPlay 2 nativ
- **moOde**: Hat AirPlay 2 eingebaut, aber schluckt ~300 MB RAM → zu viel für Pi Zero 2
- **Lyrion/LMS**: Overkill für einen einzelnen Raum; als Server auf dem Proxmox-Host sinnvoller

### Was geht noch auf dem Pi Zero 2 parallel?

Dank **ALSA dmix** laufen AirPlay 2 + Mopidy (Subsonic-Client) gleichzeitig:

- **AirPlay 2** von iPhone/Mac (Lautstärke iPhone-geregelt)
- **Subsonic/Subidy** für die eigene Nextcloud-Musikbibliothek
- **Internetradio** aus M3U-Playlisten (via Mopidy)

---

## Pre-built Binaries 🇩🇪

Du musst **nicht selbst kompilieren** — jedes Release enthält fertige ARM64-Binaries.

👉 **[Releases](https://github.com/aimlessjohn-hub/pi-zero-airplay2/releases)**

```bash
# Auf dem Pi Zero 2:
wget https://github.com/aimlessjohn-hub/pi-zero-airplay2/releases/download/v1.0.0/airplay2-arm64.tar.gz
tar -xzf airplay2-arm64.tar.gz
sudo cp -r build/nqptp/usr/local/* /usr/local/
sudo cp -r build/shairport-sync/usr/local/* /usr/local/
sudo cp configs/nqptp.service /etc/systemd/system/
sudo cp configs/shairport-sync.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now nqptp shairport-sync
```

> **Hinweis:** Die Binaries sind für Debian 13 / Raspberry Pi OS Bookworm (arm64) kompiliert. Andere Distributionen können abweichende Bibliotheksversionen haben — dann selbst bauen mit `build-airplay2.sh`.

## Pre-built Binaries 🇬🇧

**No need to compile from source** — every release includes ready-to-use ARM64 binaries.

👉 **[Releases](https://github.com/aimlessjohn-hub/pi-zero-airplay2/releases)**

```bash
# On the Pi Zero 2:
wget https://github.com/aimlessjohn-hub/pi-zero-airplay2/releases/download/v1.0.0/airplay2-arm64.tar.gz
tar -xzf airplay2-arm64.tar.gz
sudo cp -r build/nqptp/usr/local/* /usr/local/
sudo cp -r build/shairport-sync/usr/local/* /usr/local/
sudo cp configs/nqptp.service /etc/systemd/system/
sudo cp configs/shairport-sync.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now nqptp shairport-sync
```

> **Note:** Binaries are compiled for Debian 13 / Raspberry Pi OS Bookworm (arm64). Other distros may have different library versions — build from source with `build-airplay2.sh`.

---

## Build Details 🇩🇪 🇬🇧

| Component | Version | Source | Build Flag |
|---|---|---|---|
| nqptp | 1.2.1-99 (HEAD) | [mikebrady/nqptp](https://github.com/mikebrady/nqptp) | `--with-systemd-startup` |
| Shairport-Sync | 5.0.4 | [mikebrady/shairport-sync](https://github.com/mikebrady/shairport-sync) | `--with-airplay-2 --with-ssl=openssl` |
| ALAC (Apple Lossless) | HEAD | [mikebrady/alac](https://github.com/mikebrady/alac) | cmake |
| DAC | Apple USB-C Adapter (Cirrus Logic) | fixed 48 kHz | Hardware mixer "Headphone" |

All builds run on **native ARM64** via GitHub Actions (`ubuntu-24.04-arm`). No QEMU, no cross-compilation.

---

## License 🇩🇪 🇬🇧

Dieses Projekt steht unter der **GPL-3.0-Lizenz**.
*This project is licensed under the **GPL-3.0 License**.*

- Shairport-Sync © Mike Brady, GPL-2.0+ / [Source](https://github.com/mikebrady/shairport-sync)
- nqptp © Mike Brady, GPL-2.0+ / [Source](https://github.com/mikebrady/nqptp)
- ALAC © Mike Brady, Apache 2.0 / [Source](https://github.com/mikebrady/alac)
- Configs + Build script: own work, GPL-3.0

---

## Credits 🇩🇪 🇬🇧

- [Mike Brady](https://github.com/mikebrady) – Shairport-Sync, nqptp & ALAC
- [Mopidy](https://mopidy.com/) – Music server
- [Subidy](https://github.com/nickoala/subidy) – Mopidy Subsonic plugin
- [Raspberry Pi Foundation](https://www.raspberrypi.com/) – Pi Zero 2 W