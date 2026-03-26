#!/usr/bin/env bash
# mkflake - scaffold a nix devshell flake in the current directory
#
# Usage:
#   mkflake                          # interactive package prompt
#   mkflake python310 nodejs_20      # packages as arguments
#   NIXPKGS=nixos-24.11 mkflake ...  # override nixpkgs channel

set -euo pipefail

NIXPKGS="${NIXPKGS:-nixos-unstable}"
ARCH="x86_64-linux"

# ── Collect packages ────────────────────────────────────────────────────────

if [ $# -gt 0 ]; then
  packages=("$@")
else
  echo "Packages to include (empty line when done):"
  packages=()
  while true; do
    read -r -p "  + " pkg
    [[ -z "$pkg" ]] && break
    packages+=("$pkg")
  done
fi

if [ ${#packages[@]} -eq 0 ]; then
  echo "No packages specified, aborting." >&2
  exit 1
fi

# ── Guard against overwriting existing files ────────────────────────────────

for f in flake.nix .envrc; do
  if [ -f "$f" ]; then
    read -r -p "$f already exists — overwrite? [y/N] " ans
    [[ "${ans,,}" == "y" ]] || { echo "Skipping $f."; continue; }
  fi
done

# ── Build package list ───────────────────────────────────────────────────────

pkg_lines=""
for pkg in "${packages[@]}"; do
  pkg_lines+="        ${pkg}"$'\n'
done

# ── Write files ──────────────────────────────────────────────────────────────

cat > flake.nix << EOF
{
  inputs.nixpkgs.url = "github:nixos/nixpkgs/${NIXPKGS}";

  outputs = { nixpkgs, ... }: {
    devShells.${ARCH}.default = nixpkgs.legacyPackages.${ARCH}.mkShell {
      packages = with nixpkgs.legacyPackages.${ARCH}; [
${pkg_lines}      ];
    };
  };
}
EOF

echo "use flake" > .envrc

# ── Allow direnv ─────────────────────────────────────────────────────────────

direnv allow

echo ""
echo "Ready — flake.nix and .envrc created with:"
for pkg in "${packages[@]}"; do
  echo "  • $pkg"
done
echo ""
echo "Run 'nix develop' or re-enter the directory to activate."
