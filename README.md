# pi-zero-airplay2

> AirPlay 2 auf dem Raspberry Pi Zero 2 W — selbst kompiliert, optimiert, reproduzierbar.

Dieses Repository enthält alles, um einen **Pi Zero 2 W** in einen vollwertigen **AirPlay-2-Empfänger** zu verwandeln – inklusive parallelem **Mopidy/Subsonic**-Musikstreaming von der eigenen Nextcloud.

## Features

- ✅ **AirPlay 2** – synchron mit HomePods, Apple TV, Libratone etc. (nqptp + Shairport-Sync 5)
- ✅ **AirPlay 1 Fallback** – ältere Geräte streamen trotzdem
- ✅ **Nextcloud-Subsonic** – eigene Musik via Mopidy + Subidy
- ✅ **Internetradio** – M3U-Playlisten, läuft parallel
- ✅ **Parallele Ausgabe** – AirPlay + Mopidy gleichzeitig (ALSA dmix)
- ✅ **Auto-Pause** – AirPlay pausiert Mopidy, Resume nach Ende
- ✅ **Hardware-Volume** – Apple USB-C DAC, Volume pro Dienst getrennt
- ✅ **Geringer Footprint** – ~220 MB RAM nach AirPlay 2 Start
- ✅ **GitHub Actions** – Automatische ARM-Builds, keine Cross-Compile nötig

## Repository-Struktur

```
pi-zero-airplay2/
├── README.md                    # Diese Datei (DE/EN)
├── LICENSE                      # GPL-3.0
├── build-airplay2.sh            # Build-Skript für AirPlay 2 auf Pi Zero 2
├── configs/
│   ├── shairport-sync.conf      # AirPlay 2 Konfiguration
│   ├── nqptp.service            # systemd-Dienst für nqptp (PTP-Sync)
│   ├── shairport-sync.service   # systemd-Dienst für Shairport-Sync
│   ├── asound.conf              # ALSA dmix für parallelen DAC-Zugriff
│   ├── mopidy.conf              # Mopidy-Konfiguration (Subsonic + Radio)
│   └── airplay-mopidy.sh        # Pause/Resume bei AirPlay
└── .github/workflows/
    └── build.yml                # GitHub Actions (ARM64-Builds)
```

## Quick Start

### 1. Voraussetzungen

- Raspberry Pi Zero 2 W mit **Raspberry Pi OS Lite (64-bit)** oder **Debian 13 (Trixie) arm64**
- USB-DAC (z. B. Apple USB-C Headphone Adapter)
- Internetzugang (WLAN oder Ethernet via OTG)
- SSH-Zugriff

### 2. Build-Skript ausführen

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

## Background – Warum AirPlay 2 auf dem Pi Zero 2?

Der Pi Zero 2 W hat nur **512 MB RAM** und einen Quad-Core **Cortex-A53** bei 1 GHz. Offizielle Binärpakete von Shairport-Sync gibt es nur als AirPlay 1 (`apt install shairport-sync`). AirPlay 2 benötigt:

1. **nqptp** – Network Quality of Service Precision Time Protocol (PTP-Synchronisation)
2. **Shairport-Sync ≥ 4.0** mit `--with-airplay-2` Flag

Beide müssen **aus dem Quellcode kompiliert** werden. Das Build-Skript in diesem Repo macht genau das – reproduzierbar und dokumentiert.

### Warum kein piCorePlayer / moOde / Lyrion?

- **piCorePlayer**: Läuft nur als Squeezelite, kein AirPlay 2 nativ
- **moOde**: Hat AirPlay 2 eingebaut, aber schluckt ~300 MB RAM → zu viel für Pi Zero 2
- **Lyrion/LMS**: Overkill für einen einzelnen Raum; als Server auf dem Proxmox-Host sinnvoller

### Was geht noch auf dem Pi Zero 2 parallel?

Dank **ALSA dmix** laufen AirPlay 2 + Mopidy (Subsonic-Client) gleichzeitig. Damit hast du:

- **AirPlay 2** von iPhone/Mac (Lautstärke iPhone-geregelt)
- **Subsonic/Subidy** für die eigene Nextcloud-Musikbibliothek
- **Internetradio** aus M3U-Playlisten (via Mopidy)

die Configs in `configs/` zeigen genau, wie das funktioniert.

---

## Build-Details

| Komponente | Version | Quelle |
|---|---|---|
| nqptp | 1.2.1-99 (HEAD) | [mikebrady/nqptp](https://github.com/mikebrady/nqptp) |
| Shairport-Sync | 5.0.4 | [mikebrady/shairport-sync](https://github.com/mikebrady/shairport-sync) |
| Build-Flags | `--with-airplay-2 --with-ssl=openssl` | |
| DAC | Apple USB-C Headphone Adapter (Cirrus Logic) | fixed 48 kHz, Hardware-Volume |

Alle Builds laufen automatisch via **GitHub Actions**: ARM64-Binaries werden bei jedem Release gebaut und als Artefakt bereitgestellt.

---

## Lizenz

Dieses Projekt steht unter der **GPL-3.0-Lizenz**.

Shairport-Sync ist © Mike Brady, GPL-2.0+.
nqptp ist © Mike Brady, GPL-2.0+.
Die Konfigurationsdateien und das Build-Skript sind eigene Arbeit, ebenfalls GPL-3.0.

---

## Credits

- [Mike Brady](https://github.com/mikebrady) – Shairport-Sync und nqptp
- [Mopidy](https://mopidy.com/) – Musikserver
- [Subidy](https://github.com/nickoala/subidy) – Mopidy-Subsonic-Plugin
- [Raspberry Pi Foundation](https://www.raspberrypi.com/) – Pi Zero 2 W

---

## English Summary

> **pi-zero-airplay2** turns a Raspberry Pi Zero 2 W into a full AirPlay 2 receiver — self-compiled, optimized, and reproducible. Includes parallel Mopidy/Subsonic streaming, Internet radio, auto-pause on AirPlay, and hardware volume support. All configs, a build script, and GitHub Actions for automated ARM builds are included.