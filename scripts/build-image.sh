#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG="$ROOT/config/image.env"
WORK="$ROOT/.work/image-build"
OUT="$ROOT/out"

[[ -f "$CONFIG" ]] || { echo "Missing $CONFIG" >&2; exit 1; }
# shellcheck disable=SC1090
source "$CONFIG"

: "${IMAGE:?IMAGE is required}"
: "${IMAGE_URL:?IMAGE_URL is required}"
: "${IMAGE_SHA256:?IMAGE_SHA256 is required}"

for cmd in curl sha256sum xz losetup mount umount rsync; do
    command -v "$cmd" >/dev/null 2>&1 || { echo "Missing command: $cmd" >&2; exit 1; }
done

rm -rf "$WORK"
mkdir -p "$WORK/download" "$WORK/mnt/boot" "$WORK/mnt/root" "$OUT"

ARCHIVE="$WORK/download/$IMAGE.img.xz"
RAW="$WORK/$IMAGE.img"
OUTPUT="$OUT/brainbox-zero.img.xz"

echo "Downloading $IMAGE"
curl --fail --location --output "$ARCHIVE" "$IMAGE_URL"

echo "$IMAGE_SHA256  $ARCHIVE" | sha256sum --check -

echo "Decompressing base image"
xz --decompress --keep "$ARCHIVE"
mv "$WORK/download/$IMAGE.img" "$RAW"

LOOP=""
cleanup() {
    set +e
    mountpoint -q "$WORK/mnt/boot" && umount "$WORK/mnt/boot"
    mountpoint -q "$WORK/mnt/root" && umount "$WORK/mnt/root"
    [[ -n "$LOOP" ]] && losetup -d "$LOOP"
}
trap cleanup EXIT

LOOP="$(losetup --find --partscan --show "$RAW")"
mount "${LOOP}p1" "$WORK/mnt/boot"
mount "${LOOP}p2" "$WORK/mnt/root"

echo "Applying boot overlay"
if [[ -d "$ROOT/overlay/bootfs" ]]; then
    rsync -a --chown=0:0 "$ROOT/overlay/bootfs/" "$WORK/mnt/boot/"
fi

echo "Applying root filesystem overlay"
if [[ -d "$ROOT/overlay/rootfs" ]]; then
    rsync -a --chown=0:0 "$ROOT/overlay/rootfs/" "$WORK/mnt/root/"
fi

CONFIG_TXT="$WORK/mnt/boot/config.txt"
if ! grep -Fxq 'include brainbox-zero-config.txt' "$CONFIG_TXT"; then
    printf '\n# Brainbox Zero image configuration\ninclude brainbox-zero-config.txt\n' >>"$CONFIG_TXT"
fi

CMDLINE="$WORK/mnt/boot/cmdline.txt"
CMDLINE_VALUE="$(tr -d '\r\n' <"$CMDLINE")"
if [[ " $CMDLINE_VALUE " != *" console=serial0,115200 "* ]]; then
    CMDLINE_VALUE="$CMDLINE_VALUE console=serial0,115200"
fi
printf '%s\n' "$CMDLINE_VALUE" >"$CMDLINE"

cat >"$WORK/mnt/root/etc/brainbox-zero-image" <<EOF
IMAGE=$IMAGE
IMAGE_SHA256=$IMAGE_SHA256
BUILD_REPOSITORY=${GITHUB_REPOSITORY:-local}
BUILD_COMMIT=${GITHUB_SHA:-local}
EOF

if [[ -f "$WORK/mnt/root/usr/local/bin/verify-brainbox-zero" ]]; then
    chmod 0755 "$WORK/mnt/root/usr/local/bin/verify-brainbox-zero"
fi

echo "Verifying mounted image"
grep -Fxq 'include brainbox-zero-config.txt' "$CONFIG_TXT"
grep -q 'console=serial0,115200' "$CMDLINE"
grep -Fxq 'enable_uart=1' "$WORK/mnt/boot/brainbox-zero-config.txt"
test -s "$WORK/mnt/root/etc/brainbox-zero-image"
test -x "$WORK/mnt/root/usr/local/bin/verify-brainbox-zero"

sync
umount "$WORK/mnt/boot"
umount "$WORK/mnt/root"
losetup -d "$LOOP"
LOOP=""

echo "Compressing output"
xz --threads=0 --compress --keep --force "$RAW"
mv "$RAW.xz" "$OUTPUT"

(
    cd "$OUT"
    sha256sum "$(basename "$OUTPUT")" >"$(basename "$OUTPUT").sha256"
)

echo "Built: $OUTPUT"
