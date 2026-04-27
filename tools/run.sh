#!/bin/bash
set -euo pipefail
# -e: bricht bei Fehler sofort ab
# -u: ungesetzte Variablen werden als Fehler behandelt
# -o pipefail: Fehler in Pipes (z.B. curl | cut) werden weitergegeben

# Arbeitsverzeichnis = Repo-Root
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR/.."

echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] Downloading egress IP ranges..."

# curl:
#   -f: Fehler bei HTTP 4xx/5xx
#   -s: kein Fortschrittsbalken
#   -S: zeigt Fehler trotz -s
#   -L: folgt Redirects
curl -fsSL "https://mask-api.icloud.com/egress-ip-ranges.csv" \
  | cut -d ',' -f 1 \
  > egress-ip-ranges.txt

if [ ! -s egress-ip-ranges.txt ]; then
  echo "ERROR: Downloaded file is empty" >&2
  exit 1
fi

echo "Downloaded: $(wc -l < egress-ip-ranges.txt) entries"

# IPv4: strikteres Pattern mit {1,3} statt .+
grep -E '^([0-9]{1,3}\.){3}[0-9]{1,3}(/[0-9]{1,2})?$' egress-ip-ranges.txt > ipv4-only.txt || true
# IPv6: grep auf ':' zuverlässiger als Hex-Regex (matched auch ::1, fe80:: etc.)
grep ':' egress-ip-ranges.txt > ipv6-only.txt || true

echo "IPv4 before merge: $(wc -l < ipv4-only.txt)"
echo "IPv6 before merge: $(wc -l < ipv6-only.txt)"

if [ ! -s ipv4-only.txt ]; then
  echo "ERROR: No IPv4 ranges found" >&2
  exit 1
fi
if [ ! -s ipv6-only.txt ]; then
  echo "ERROR: No IPv6 ranges found" >&2
  exit 1
fi

echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] Merging CIDRs..."

# cidr-merger -e: bricht ab wenn Input leer ist
cidr-merger -e egress-ip-ranges.txt > ip-ranges.txt
cidr-merger -e ipv4-only.txt        > ipv4/ipv4-ranges.txt
cidr-merger -e ipv6-only.txt        > ipv6/ipv6-ranges.txt

echo "Combined after merge : $(wc -l < ip-ranges.txt)"
echo "IPv4    after merge  : $(wc -l < ipv4/ipv4-ranges.txt)"
echo "IPv6    after merge  : $(wc -l < ipv6/ipv6-ranges.txt)"

echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] Generating NGINX geo format..."

awk '{print $1 " yes;"}' ip-ranges.txt        > ip-ranges-geo.txt
awk '{print $1 " yes;"}' ipv4/ipv4-ranges.txt > ipv4/ipv4-ranges-geo.txt
awk '{print $1 " yes;"}' ipv6/ipv6-ranges.txt > ipv6/ipv6-ranges-geo.txt

echo "Geo combined : $(wc -l < ip-ranges-geo.txt)"
echo "Geo IPv4     : $(wc -l < ipv4/ipv4-ranges-geo.txt)"
echo "Geo IPv6     : $(wc -l < ipv6/ipv6-ranges-geo.txt)"

echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] Done."
