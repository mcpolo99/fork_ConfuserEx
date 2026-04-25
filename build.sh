#!/bin/bash
set -e

ROOT="$(cd "$(dirname "$0")" && pwd)"
CONFIG="${1:-Release}"
OUTPUT="${2:-$ROOT/bin/$CONFIG}"

# Find MSBuild via vswhere
MSBUILD="$("$(cygpath 'C:\Program Files (x86)\Microsoft Visual Studio\Installer\vswhere.exe')" \
    -latest -requires Microsoft.Component.MSBuild \
    -find 'MSBuild\**\Bin\MSBuild.exe' 2>/dev/null | head -1)"

if [ -z "$MSBUILD" ]; then
    echo "[ERROR] MSBuild not found. Install Visual Studio with C++ build tools."
    exit 1
fi

MSBUILD="$(cygpath "$MSBUILD")"
WIN_SLN="$(cygpath -w "$ROOT/Confuser2.sln")"

echo "============================================"
echo " Building ConfuserEx ($CONFIG)"
echo "============================================"

"$MSBUILD" -t:Restore "$WIN_SLN"
"$MSBUILD" -p:Configuration="$CONFIG" "$WIN_SLN"

# Verify core outputs exist
CLI_BIN="$ROOT/Confuser.CLI/bin/$CONFIG/net461"
GUI_BIN="$ROOT/ConfuserEx/bin/$CONFIG/net461"

if [ ! -f "$CLI_BIN/Confuser.CLI.exe" ]; then
    echo "[ERROR] Build failed — Confuser.CLI.exe not found."
    exit 1
fi

echo "[OK] ConfuserEx built."

# Clear and copy to output directory
rm -rf "$OUTPUT"
mkdir -p "$OUTPUT"

# CLI has all shared libs — copy first
cp -r "$CLI_BIN/"* "$OUTPUT/"

# GUI adds its exe + WPF dependencies on top
if [ -f "$GUI_BIN/ConfuserEx.exe" ]; then
    cp -r "$GUI_BIN/"* "$OUTPUT/"
    echo "[OK] CLI + GUI -> $OUTPUT"
else
    echo "[OK] CLI -> $OUTPUT (GUI not built)"
fi
