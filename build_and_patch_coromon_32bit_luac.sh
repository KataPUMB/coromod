#!/usr/bin/env bash
set -euo pipefail

STEAMAPPS="$HOME/snap/steam/common/.local/share/Steam/steamapps"
GAME_DIR="$STEAMAPPS/common/Coromon"
RESOURCE_CAR="$GAME_DIR/Resources/resource.car"

WORKDIR="/tmp/coromonUnpacked"
ARCHIVER="/tmp/corona-archiver/corona-archiver.py"

BACKUP_DIR="/tmp/coromon_resource_backups"
BUILD_DIR="/tmp/coromon_build"
LUAC32="/tmp/lua-5.1.5/src/luac"

TIMESTAMP="$(date +%F_%H%M%S)"

mkdir -p "$BACKUP_DIR"
mkdir -p "$BUILD_DIR"

echo "== Coromon resource.car patch =="
echo ""
echo "GAME_DIR:     $GAME_DIR"
echo "RESOURCE_CAR: $RESOURCE_CAR"
echo "WORKDIR:      $WORKDIR"
echo "ARCHIVER:     $ARCHIVER"
echo ""

FILES_TO_COMPILE=(
    "classes.monsters.Monster"
    "classes.world.effects.world.potentialRerollWorldEffect"
    "classes.world.effects.world.potentialStatSoftResetWorldEffect"
    "classes.world.effects.world.traitRerollWorldEffect"
    "classes.world.effects.world.spinnerSwapWorldEffect"
)

if [ ! -d "$GAME_DIR" ]; then
    echo "ERROR: no existe la carpeta del juego:"
    echo "$GAME_DIR"
    exit 1
fi

if [ ! -f "$RESOURCE_CAR" ]; then
    echo "ERROR: no existe resource.car:"
    echo "$RESOURCE_CAR"
    exit 1
fi

if [ ! -d "$WORKDIR" ]; then
    echo "ERROR: no existe WORKDIR:"
    echo "$WORKDIR"
    exit 1
fi

if [ ! -f "$ARCHIVER" ]; then
    echo "ERROR: no existe corona-archiver:"
    echo "$ARCHIVER"
    exit 1
fi

echo "1) Comprobando archivos modificados y originales"
echo ""

for module in "${FILES_TO_COMPILE[@]}"; do
    lua_file="$WORKDIR/decompiled_all/$module.lua"
    lu_file="$WORKDIR/$module.lu"

    echo "Module: $module"
    echo "  Lua modificado: $lua_file"
    echo "  Lu destino:     $lu_file"

    if [ ! -f "$lua_file" ]; then
        echo "ERROR: no existe el Lua modificado:"
        echo "$lua_file"
        exit 1
    fi

    if [ ! -f "$lu_file" ]; then
        echo "ERROR: no existe el .lu original:"
        echo "$lu_file"
        exit 1
    fi

    echo "  OK"
    echo ""
done

echo "2) Preparando luac Lua 5.1 de 32 bits"
echo ""

if [ ! -f "$LUAC32" ]; then
    echo "No existe $LUAC32. Lo compilo ahora."

    sudo apt update
    sudo apt install -y build-essential gcc-multilib libc6-dev-i386 make curl

    cd /tmp

    if [ ! -d "/tmp/lua-5.1.5" ]; then
        curl -L "https://www.lua.org/ftp/lua-5.1.5.tar.gz" -o /tmp/lua-5.1.5.tar.gz
        tar -xzf /tmp/lua-5.1.5.tar.gz
    fi

    cd /tmp/lua-5.1.5
    make clean || true
    make ansi CC="gcc -m32"
else
    echo "Ya existe luac 32-bit:"
    echo "$LUAC32"
fi

if [ ! -f "$LUAC32" ]; then
    echo "ERROR: no se generó luac de 32 bits:"
    echo "$LUAC32"
    exit 1
fi

echo ""
echo "luac detectado:"
file "$LUAC32" || true
"$LUAC32" -v || true
echo ""

echo "3) Backup del resource.car original"
echo ""

RESOURCE_BACKUP="$BACKUP_DIR/resource.car.backup.$TIMESTAMP"
cp -av "$RESOURCE_CAR" "$RESOURCE_BACKUP"

echo ""
echo "Backup resource.car:"
echo "$RESOURCE_BACKUP"
echo ""

echo "4) Backup de cada .lu original"
echo ""

for module in "${FILES_TO_COMPILE[@]}"; do
    lu_file="$WORKDIR/$module.lu"
    backup_file="$lu_file.backup.$TIMESTAMP"

    cp -av "$lu_file" "$backup_file"
done

echo ""
echo "5) Comprobando sintaxis de cada Lua modificado"
echo ""

for module in "${FILES_TO_COMPILE[@]}"; do
    lua_file="$WORKDIR/decompiled_all/$module.lua"

    echo "Checking syntax: $lua_file"
    "$LUAC32" -p "$lua_file"
done

echo ""
echo "OK: todos los Lua tienen sintaxis válida"
echo ""

echo "6) Compilando Lua modificados a .lu compatibles"
echo ""

for module in "${FILES_TO_COMPILE[@]}"; do
    lua_file="$WORKDIR/decompiled_all/$module.lua"
    lu_file="$WORKDIR/$module.lu"

    echo "Compiling:"
    echo "  $lua_file"
    echo "  -> $lu_file"

    "$LUAC32" -s -o "$lu_file" "$lua_file"

    echo "  Generated:"
    ls -lh "$lu_file"

    echo "  Header:"
    xxd -l 16 "$lu_file" || true

    echo ""
done

echo "7) Reempaquetando resource.car"
echo ""

NEW_CAR="$BUILD_DIR/resource.car.patched.$TIMESTAMP"

cd /tmp
python3 "$ARCHIVER" -p "$WORKDIR" "$NEW_CAR"

if [ ! -f "$NEW_CAR" ]; then
    echo "ERROR: no se generó el nuevo resource.car:"
    echo "$NEW_CAR"
    exit 1
fi

echo ""
echo "Nuevo resource.car generado:"
ls -lh "$NEW_CAR"
echo ""

echo "8) Reemplazando resource.car del juego"
echo ""

cp -av "$NEW_CAR" "$RESOURCE_CAR"

echo ""
echo "DONE"
echo ""
echo "Backup del resource.car original:"
echo "$RESOURCE_BACKUP"
echo ""
echo "Nuevo resource.car generado:"
echo "$NEW_CAR"
echo ""
echo "Si el juego no arranca, restaura con:"
echo "cp -av \"$RESOURCE_BACKUP\" \"$RESOURCE_CAR\""