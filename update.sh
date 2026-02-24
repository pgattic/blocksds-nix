#!/usr/bin/env nix-shell
#!nix-shell -i bash -p nix-prefetch-docker fd jq
set -euo pipefail

IMAGE="skylyrac/blocksds"
mkdir -p sources
changed=0

fetch() {
  local tag="$1" arch="$2" out="$3"
  local tmp
  tmp="$(mktemp)"

  echo "prefetching ${IMAGE}:${tag} (${arch})"
  nix-prefetch-docker \
    --image-name "$IMAGE" \
    --image-tag "$tag" \
    --arch "$arch" \
    --json --quiet >"$tmp"

  # If file doesn't exist yet, that's a change
  if [ ! -f "sources/$out" ] || ! cmp -s "sources/$out" "$tmp"; then
    mv "$tmp" "sources/$out"
    changed=1
  else
    rm -f "$tmp"
  fi
}

fetch "slim-latest" "amd64" "blocksds-slim-amd64.json"
fetch "slim-latest" "arm64" "blocksds-slim-arm64.json"
fetch "dev-latest" "amd64" "blocksds-dev-amd64.json"
fetch "dev-latest" "arm64" "blocksds-dev-arm64.json"

if [ "$changed" -eq 0 ]; then
  echo "No source changes; exiting."
  exit 0
fi

# Update flake inputs
fd flake.nix -x nix flake update --flake "{//}" --option access-tokens "github.com=$GITHUB_TOKEN"

# Build examples
nix build ./examples/*

# Emit a commit message helper (digest snippets)
slim_amd64_digest="$(jq -r .imageDigest sources/blocksds-slim-amd64.json | cut -c1-19)"
dev_amd64_digest="$(jq -r .imageDigest sources/blocksds-dev-amd64.json  | cut -c1-19)"
msg="Update BlocksDS images (slim ${slim_amd64_digest}, dev ${dev_amd64_digest})"
echo "$msg" > .git/blocksds-update-message

