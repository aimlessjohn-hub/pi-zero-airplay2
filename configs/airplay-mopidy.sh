#!/usr/bin/env bash
# airplay-mopidy.sh – Pause/Resume Mopidy bei AirPlay
#
# Wird von Shairport-Sync via run_this_before/after_playing aufgerufen.
# Pausiert Mopidy während AirPlay aktiv ist, resumed danach.

MOPIDY_HOST="localhost"
MOPIDY_PORT="6600"

case "${1:-}" in
  start)
    # AirPlay startet → Mopidy pausieren
    printf "pause\nclose\n" | nc -q 1 "$MOPIDY_HOST" "$MOPIDY_PORT" >/dev/null 2>&1
    ;;
  stop)
    # AirPlay endet → Mopidy fortsetzen
    printf "play\nclose\n" | nc -q 1 "$MOPIDY_HOST" "$MOPIDY_PORT" >/dev/null 2>&1
    ;;
esac