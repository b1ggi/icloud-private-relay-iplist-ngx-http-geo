#!/bin/sh

## build basics
curl -sSL "https://mask-api.icloud.com/egress-ip-ranges.csv" | cut -d ',' -f 1 > egress-ip-ranges.txt && \
  grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+(/[0-9]+)?$' egress-ip-ranges.txt > ipv4-only.txt && \
  grep -E '^[0-9a-fA-F:]+(/[0-9]+)?$' egress-ip-ranges.txt > ipv6-only.txt && \
  wc -l egress-ip-ranges.txt && \
  wc -l ipv4-only.txt && \
  wc -l ipv6-only.txt && \
  cidr-merger -eo ip-ranges.txt egress-ip-ranges.txt && \
  cidr-merger -eo ipv4/ipv4-ranges.txt ipv4-only.txt && \
  cidr-merger -eo ipv6/ipv6-ranges.txt ipv6-only.txt && \
  wc -l ip-ranges.txt && \
  wc -l ipv4/ipv4-ranges.txt && \
  wc -l ipv6/ipv6-ranges.txt

awk '{print $1 " yes;"}' ip-ranges.txt > ip-ranges-geo.txt
awk '{print $1 " yes;"}' ipv4/ipv4-ranges.txt > ipv4/ipv4-ranges-geo.txt
awk '{print $1 " yes;"}' ipv6/ipv6-ranges.txt > ipv6/ipv6-ranges-geo.txt
wc -l ip-ranges-geo.txt
wc -l ipv4/ipv4-ranges-geo.txt
wc -l ipv6/ipv6-ranges-geo.txt
