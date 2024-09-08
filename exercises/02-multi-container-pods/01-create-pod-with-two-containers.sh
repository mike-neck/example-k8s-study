#!/usr/bin/env bash

kubectl create --filename <(kubectl run busybox \
  --image=ubuntu:24.04 \
  --restart=Never \
  --dry-run=client \
  --output json \
  --command -- /usr/bin/bash -c 'declare cnt; for cnt in {1..24}; do echo "[$(date "+%Y-%m-%dT%H:%M:%S")] loop-${cnt}"; sleep 30; done' | \
jq '.spec.containers[0].name = "busy-box-1" | .spec.containers[1] = (.spec.containers[0] | .name = "busy-box-2")' | \
yj -jy
)
