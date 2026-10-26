#!/usr/bin/env bash
# Build this branch with the toolchain of upstream's era: ARM's GNU Embedded
# 6-2017-q2-update (GCC 6.3.1, June 2017), the release current when upstream
# myevic last shipped a binary (August 2017).
#
# WHY THIS BRANCH EXISTS. The `pufflimit` branch builds with a current GCC,
# which needed fixes to the Makefile, linker script and startup assembly just
# to build, and produces an image about 2 KB larger than upstream's for the
# same source. Its first hardware test did not boot. This branch keeps
# upstream's build files untouched and adds only the limiter source, so the
# modern toolchain and those fixes can be ruled in or out.
#
# Upstream's exact toolchain could NOT be reproduced: the shipped
# bin/myevic.bin matches none of ARM GCC 6.2.1/6.3.1, Debian GCC 5.4.1, or
# Debian clang 3.8/3.9/4.0. The evidence (upstream's last Makefile edit) points
# at an unreleased or Apple clang with ARM 6.x libraries. GCC 6.3.1 is the
# closest reproducible choice, and it builds upstream's own source unmodified.
#
# Upstream's Makefile expects a Debian-style library layout, so the library
# directories are passed on the command line instead of editing it. Output goes
# to build/ (OUTDIR is overridden too), so the tracked bin/myevic.bin, which is
# upstream's stock build, is never overwritten or deleted by `make clean`.
#
# Needs: curl, tar, sha256sum, make, and `evic` (python-evic) on PATH.
# Usage:  ./build-gcc6.sh             this branch (the limiter)
#                                       -> build/myevic.bin (encrypted, flashable)
#         ./build-gcc6.sh --upstream  upstream myevic's own source, commit
#                                     546394b, unmodified, same toolchain
#                                       -> build/upstream/myevic.bin
#
# --upstream exists for testing in steps: if upstream's shipped binary boots
# but our build does not, building upstream's own source with this toolchain
# tells you whether the toolchain or the limiter is to blame.

set -euo pipefail

name=gcc-arm-none-eabi-6-2017-q2-update
url=https://developer.arm.com/-/media/Files/downloads/gnu-rm/6-2017q2/$name-linux.tar.bz2
# SHA-256 of the tarball as downloaded from the URL above.
sha=e68e4b2fe348ecb567c27985355dff75b65319a0f6595d44a18a8c5e05887cc3

cache=${XDG_CACHE_HOME:-$HOME/.cache}/evic-toolchains
tarball=$cache/$name-linux.tar.bz2
root=$cache/$name
mkdir -p "$cache"

if [ ! -x "$root/bin/arm-none-eabi-gcc" ]; then
    [ -s "$tarball" ] || curl -fL -o "$tarball" "$url"
    echo "$sha  $tarball" | sha256sum -c -
    tar -xjf "$tarball" -C "$cache"
fi

command -v evic >/dev/null || { echo "evic (python-evic) not on PATH" >&2; exit 1; }

ver=$("$root/bin/arm-none-eabi-gcc" -dumpversion)
export PATH="$root/bin:$PATH"
libdirs="-L$root/arm-none-eabi/lib/thumb -L$root/lib/gcc/arm-none-eabi/$ver/thumb"
here=$(pwd)

if [ "${1:-}" = --upstream ]; then
    # Build upstream's last commit in a throwaway worktree, so this checkout
    # is not touched. The SDK is linked in from here.
    src=$(mktemp -d)
    trap 'git -C "$here" worktree remove --force "$src" 2>/dev/null; rm -rf "$src"' EXIT
    git worktree add -q --detach "$src" 546394b
    ln -s "$here/nuvoton-sdk" "$src/nuvoton-sdk"
    out=$here/build/upstream
    (cd "$src" && EVICSDK=. make OUTDIR=build LIBDIRS="$libdirs")
    mkdir -p "$out"
    cp "$src"/build/myevic.bin "$src"/build/myevic_dec.bin "$src"/build/myevic.elf "$out/"
else
    out=$here/build
    export EVICSDK=${EVICSDK:-.}
    make OUTDIR=build clean
    make OUTDIR=build LIBDIRS="$libdirs"
fi

# Upstream's linker script does not check the .data load image against ROM,
# so an image too big for the chip links without complaint and its tail
# lands on the custom-logo pages at 0x19000. Check here instead. 100K is
# linker.ld's ROM length.
rom=$((100 * 1024))
size=$(stat -c%s "$out/myevic_dec.bin")
if [ "$size" -gt "$rom" ]; then
    echo "IMAGE TOO BIG: $size bytes, ROM is $rom. Do not flash $out/myevic.bin." >&2
    rm -f "$out/myevic.bin"
    exit 1
fi

echo
"$root/bin/arm-none-eabi-gcc" --version | head -1
echo "image: $size of $rom bytes ($((rom - size)) free)"
sha256sum "$out/myevic.bin"
