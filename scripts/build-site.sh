#!/bin/sh
set -eu

SITE_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
CSSG_DIR=${CSSG_DIR:-"$SITE_ROOT/../../C/c-ssg"}

if [ ! -f "$CSSG_DIR/makefile" ] || [ ! -f "$CSSG_DIR/src/main.c" ]; then
    echo "c-ssg source not found at: $CSSG_DIR" >&2
    echo "Set CSSG_DIR to the directory containing c-ssg's makefile and src/." >&2
    exit 1
fi

make -C "$CSSG_DIR"

cd "$SITE_ROOT"
rm -rf htmlfiles
mkdir -p htmlfiles
TIMESTAMP=$(date -u '+%Y-%m-%d %H:%M UTC')
"$CSSG_DIR/c-ssg" --updated-at "$TIMESTAMP"
cp -R cssfiles htmlfiles/
cp -R site-imgs htmlfiles/
if [ -f resume.pdf ]; then
    cp resume.pdf htmlfiles/
fi

echo "Built site in $SITE_ROOT/htmlfiles"
