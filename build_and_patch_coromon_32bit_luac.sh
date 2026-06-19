#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

STEAMAPPS="${STEAMAPPS:-$HOME/snap/steam/common/.local/share/Steam/steamapps}"
GAME_DIR="${GAME_DIR:-$STEAMAPPS/common/Coromon}"
RESOURCE_CAR="${RESOURCE_CAR:-$GAME_DIR/Resources/resource.car}"

ARCHIVER="${ARCHIVER:-$SCRIPT_DIR/corona-archiver/corona-archiver.py}"
FILES_TO_COMPILE_DIR="${FILES_TO_COMPILE_DIR:-$SCRIPT_DIR/files-to-compile}"

BUILD_ROOT="${BUILD_ROOT:-$SCRIPT_DIR/.build}"
WORKDIR="${WORKDIR:-$BUILD_ROOT/coromonUnpacked}"
BACKUP_DIR="${BACKUP_DIR:-$SCRIPT_DIR/backups}"
COMPILED_RESOURCE_DIR="${COMPILED_RESOURCE_DIR:-$SCRIPT_DIR/compiled-resource}"

LUA_SRC_DIR="${LUA_SRC_DIR:-$SCRIPT_DIR/lua-5.1.5}"
LUAC32="${LUAC32:-$LUA_SRC_DIR/src/luac}"

TIMESTAMP="$(date +%F_%H%M%S)"
NEW_CAR="$COMPILED_RESOURCE_DIR/resource.car.patched.$TIMESTAMP"

mkdir -p "$BUILD_ROOT"
mkdir -p "$BACKUP_DIR"
mkdir -p "$COMPILED_RESOURCE_DIR"

echo "== Coromon resource.car patch =="
echo ""
echo "SCRIPT_DIR:            $SCRIPT_DIR"
echo "GAME_DIR:              $GAME_DIR"
echo "RESOURCE_CAR:          $RESOURCE_CAR"
echo "ARCHIVER:              $ARCHIVER"
echo "FILES_TO_COMPILE_DIR:  $FILES_TO_COMPILE_DIR"
echo "WORKDIR:               $WORKDIR"
echo "BACKUP_DIR:            $BACKUP_DIR"
echo "COMPILED_RESOURCE_DIR: $COMPILED_RESOURCE_DIR"
echo "LUA_SRC_DIR:           $LUA_SRC_DIR"
echo "LUAC32:                $LUAC32"
echo ""

if [ ! -d "$GAME_DIR" ]; then
    echo "ERROR: game directory not found:"
    echo "$GAME_DIR"
    exit 1
fi

if [ ! -f "$RESOURCE_CAR" ]; then
    echo "ERROR: resource.car not found:"
    echo "$RESOURCE_CAR"
    exit 1
fi

if [ ! -f "$ARCHIVER" ]; then
    echo "ERROR: corona-archiver not found:"
    echo "$ARCHIVER"
    exit 1
fi

if [ ! -d "$FILES_TO_COMPILE_DIR" ]; then
    echo "ERROR: files-to-compile directory not found:"
    echo "$FILES_TO_COMPILE_DIR"
    exit 1
fi

mapfile -t LUA_FILES < <(
    find "$FILES_TO_COMPILE_DIR" -maxdepth 1 -type f -name "*.lua" | sort
)

if [ "${#LUA_FILES[@]}" -eq 0 ]; then
    echo "ERROR: no .lua files found in:"
    echo "$FILES_TO_COMPILE_DIR"
    exit 1
fi

echo "1) Files that will be compiled and injected"
echo ""

for lua_file in "${LUA_FILES[@]}"; do
    filename="$(basename "$lua_file")"
    module="${filename%.lua}"
    target_lu="$WORKDIR/$module.lu"

    echo "Source: $lua_file"
    echo "Target: $target_lu"
    echo ""
done

echo "2) Preparing local 32-bit Lua 5.1 luac"
echo ""

if [ ! -d "$LUA_SRC_DIR" ]; then
    echo "Lua source directory not found:"
    echo "$LUA_SRC_DIR"
    echo ""
    echo "Downloading Lua 5.1.5 into the project..."

    sudo apt update
    sudo apt install -y build-essential gcc-multilib libc6-dev-i386 make curl tar

    curl -L "https://www.lua.org/ftp/lua-5.1.5.tar.gz" -o "$SCRIPT_DIR/lua-5.1.5.tar.gz"
    tar -xzf "$SCRIPT_DIR/lua-5.1.5.tar.gz" -C "$SCRIPT_DIR"
else
    echo "Lua source directory already exists:"
    echo "$LUA_SRC_DIR"
fi

if [ ! -f "$LUAC32" ]; then
    echo ""
    echo "32-bit luac not found. Building it now:"
    echo "$LUAC32"

    sudo apt update
    sudo apt install -y build-essential gcc-multilib libc6-dev-i386 make curl tar

    cd "$LUA_SRC_DIR"
    make clean || true
    make ansi CC="gcc -m32"
else
    echo ""
    echo "32-bit luac already exists:"
    echo "$LUAC32"
fi

if [ ! -f "$LUAC32" ]; then
    echo "ERROR: failed to build 32-bit luac:"
    echo "$LUAC32"
    exit 1
fi

echo ""
echo "luac detected:"
file "$LUAC32" || true
"$LUAC32" -v || true
echo ""

echo "3) Backing up original resource.car"
echo ""

RESOURCE_BACKUP="$BACKUP_DIR/resource.car.backup.$TIMESTAMP"
cp -av "$RESOURCE_CAR" "$RESOURCE_BACKUP"

echo ""
echo "Backup created:"
echo "$RESOURCE_BACKUP"
echo ""

echo "4) Unpacking original resource.car"
echo ""

rm -rf "$WORKDIR"

python3 "$ARCHIVER" -u "$RESOURCE_CAR" "$WORKDIR"

if [ ! -d "$WORKDIR" ]; then
    echo "ERROR: unpack failed. Workdir not created:"
    echo "$WORKDIR"
    exit 1
fi

echo ""
echo "Unpacked into:"
echo "$WORKDIR"
echo ""

echo "5) Checking target .lu files in unpacked resource"
echo ""

for lua_file in "${LUA_FILES[@]}"; do
    filename="$(basename "$lua_file")"
    module="${filename%.lua}"
    target_lu="$WORKDIR/$module.lu"

    echo "Source: $lua_file"
    echo "Target: $target_lu"

    if [ ! -f "$target_lu" ]; then
        echo "ERROR: target .lu file not found in unpacked resource:"
        echo "$target_lu"
        echo ""
        echo "The file name in files-to-compile must match the original resource module name."
        echo "Example:"
        echo "  files-to-compile/classes.monsters.Monster.lua"
        echo "must match:"
        echo "  resource.car/classes.monsters.Monster.lu"
        exit 1
    fi

    echo "  OK"
    echo ""
done

echo "6) Checking Lua syntax"
echo ""

for lua_file in "${LUA_FILES[@]}"; do
    echo "Checking: $lua_file"
    "$LUAC32" -p "$lua_file"
done

echo ""
echo "OK: all Lua files have valid syntax"
echo ""

echo "7) Compiling Lua files into compatible .lu bytecode"
echo ""

for lua_file in "${LUA_FILES[@]}"; do
    filename="$(basename "$lua_file")"
    module="${filename%.lua}"
    target_lu="$WORKDIR/$module.lu"

    echo "Compiling:"
    echo "  $lua_file"
    echo "  -> $target_lu"

    cp -av "$target_lu" "$target_lu.backup.$TIMESTAMP"

    "$LUAC32" -s -o "$target_lu" "$lua_file"

    echo "Generated:"
    ls -lh "$target_lu"

    if command -v xxd >/dev/null 2>&1; then
        echo "Header:"
        xxd -l 16 "$target_lu" || true
    fi

    echo ""
done

echo "8) Repacking patched resource.car"
echo ""

python3 "$ARCHIVER" -p "$WORKDIR" "$NEW_CAR"

if [ ! -f "$NEW_CAR" ]; then
    echo "ERROR: patched resource.car was not generated:"
    echo "$NEW_CAR"
    exit 1
fi

echo ""
echo "Patched resource.car created:"
ls -lh "$NEW_CAR"
echo ""

echo "9) Installing patched resource.car"
echo ""

cp -av "$NEW_CAR" "$RESOURCE_CAR"

echo ""
echo "DONE"
echo ""
echo "Original resource.car backup:"
echo "$RESOURCE_BACKUP"
echo ""
echo "Patched resource.car:"
echo "$NEW_CAR"
echo ""
echo "If the game does not start, restore the backup with:"
echo "cp -av \"$RESOURCE_BACKUP\" \"$RESOURCE_CAR\""