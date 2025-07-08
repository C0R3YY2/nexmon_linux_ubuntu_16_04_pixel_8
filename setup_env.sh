#!/usr/bin/env bash
##############################################################################
#  NexMon – environment initialisation
#  Source this from every shell BEFORE running make:
#       $ source setup_env.sh
##############################################################################

set -euo pipefail
OLD_PWD="$(pwd)"
cd "$(dirname "${BASH_SOURCE[0]}")"          # enter repo root

# ────────── general build flags ──────────
export ARCH=arm
export SUBARCH=arm
export KERNEL=kernel7

export HOSTUNAME="$(uname -s)"
export PLATFORMUNAME="$(uname -m)"
export NEXMON_ROOT="$(pwd)"
export NEXMON_SETUP_ENV=1

# ────────── choose a cross-compiler ───────
pick_legacy_toolchain() {
    case "$1" in
        darwin)  echo "$NEXMON_ROOT/buildtools/gcc-arm-none-eabi-5_4-2016q2-osx/bin" ;;
        x86_64)  echo "$NEXMON_ROOT/buildtools/gcc-arm-none-eabi-5_4-2016q2-linux-x86/bin" ;;
        arm*)    echo "$NEXMON_ROOT/buildtools/gcc-arm-none-eabi-5_4-2016q2-linux-armv7l/bin" ;;
        *)       return 1 ;;
    esac
}

if command -v arm-none-eabi-gcc >/dev/null 2>&1 ; then
    # Modern 64-bit compiler provided by the OS package manager
    ARMTC_DIR="$(dirname "$(command -v arm-none-eabi-gcc)")"
    CCPLUGIN="$NEXMON_ROOT/buildtools/gcc-nexmon-plugin/nexmon.so"
    ZLIBFLATE="zlib-flate -compress"
else
    # Fallback to bundled 32-bit compiler
    ARCH_KEY=$(echo "$HOSTUNAME" | tr '[:upper:]' '[:lower:]')
    ARMTC_DIR="$(pick_legacy_toolchain $ARCH_KEY || true)"

    if [[ -z "$ARMTC_DIR" ]] || [[ ! -x "$ARMTC_DIR/arm-none-eabi-gcc" ]]; then
        echo "❌  No usable arm-none-eabi-gcc found for this platform." >&2
        return 1
    fi

    if [[ "$HOSTUNAME" == "Darwin" ]]; then
        CCPLUGIN="$NEXMON_ROOT/buildtools/gcc-nexmon-plugin-osx/nexmon.so"
        ZLIBFLATE="openssl zlib"
    else
        CCPLUGIN="$NEXMON_ROOT/buildtools/gcc-nexmon-plugin/nexmon.so"
        ZLIBFLATE="zlib-flate -compress"
    fi
fi

export PATH="$ARMTC_DIR:$NEXMON_ROOT/buildtools:$PATH"
export CROSS_COMPILE=arm-none-eabi-
export CC="${CROSS_COMPILE}"        # Some scripts still look for $CC
export CCPLUGIN
export ZLIBFLATE

# ────────── summary ──────────
if [[ -z "${NEXMON_QUIET:-}" ]]; then
    echo "⚙  NexMon env ready"
    echo "   using: $(command -v arm-none-eabi-gcc)"
    echo "   plugin: $CCPLUGIN"
fi

cd "$OLD_PWD"
