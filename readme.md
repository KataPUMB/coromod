# Coromon Potentiflator QoL Patch

A small Linux-focused Coromon mod that makes several late-game Coromon improvement mechanics much faster and less grindy.

This project does **not** distribute Coromon's original `resource.car`. Instead, it provides modified Lua source files and a build script that lets you rebuild your own patched `resource.car` locally from your legally installed copy of the game.

## Features

This patch changes the following mechanics:

* The Potentiflator always upgrades the selected Coromon to **Perfect**.
* The Potentiflator can be used again on a Coromon that has already been potentiflated.
* Step-based world effects that normally require a long wait now complete after **5 steps** instead of **1000 steps**.

Affected world effects:

* Potentiflator / potential reroll
* Potential stat soft reset
* Trait reroll
* Spinner swap

In practice, this means the NPC/service events where you leave your Coromon for an improvement will finish almost immediately.

## Supported Version

This patch is intended for the **Linux version of Coromon**.

The default script path targets the Snap Steam installation:

```bash
~/snap/steam/common/.local/share/Steam/steamapps/common/Coromon/Resources/resource.car
```

If your Steam installation is somewhere else, you can override the path using environment variables.

Example:

```bash
RESOURCE_CAR="/path/to/Coromon/Resources/resource.car" ./build_and_patch_coromon_32bit_luac.sh
```

## Important Notes

Use this at your own risk.

Recommended before testing:

* Back up your save files.
* Disable Steam Cloud temporarily while testing.
* Use this for local/offline play only.
* Restore your original `resource.car` if the game crashes or behaves unexpectedly.

This mod changes game code. It may stop working after a game update.

## Repository Layout

Expected layout:

```text
coromod/
├── build_and_patch_coromon_32bit_luac.sh
├── corona-archiver/
├── mod/
│   ├── classes.monsters.Monster.lua
│   ├── classes.world.effects.world.potentialRerollWorldEffect.lua
│   ├── classes.world.effects.world.potentialStatSoftResetWorldEffect.lua
│   ├── classes.world.effects.world.traitRerollWorldEffect.lua
│   └── classes.world.effects.world.spinnerSwapWorldEffect.lua
└── readme.md
```

The `mod/` directory contains the modified Lua source files.

The script compiles those files into `.lu` bytecode and injects them into a rebuilt `resource.car`.

## About `corona-archiver`

Coromon uses Solar2D/Corona-style resource archives.

`corona-archiver` is used to:

1. Unpack the original `Resources/resource.car`.
2. Replace selected `.lu` files with newly compiled modified versions.
3. Repack the archive into a patched `resource.car`.

This repository expects `corona-archiver` to be available at:

```bash
./corona-archiver/corona-archiver.py
```

## How the Build Script Works

The script `build_and_patch_coromon_32bit_luac.sh` does the following:

1. Locates your Coromon installation.
2. Backs up the original `Resources/resource.car`.
3. Uses `corona-archiver` to unpack the original archive into a local `.build/` directory.
4. Builds a 32-bit Lua 5.1 compiler if one is not already available.
5. Checks the syntax of the modified Lua files in `mod/`.
6. Compiles those Lua files into Solar2D-compatible `.lu` bytecode.
7. Replaces the matching `.lu` files in the unpacked archive.
8. Repackages everything into a new patched `resource.car`.
9. Installs the patched `resource.car` into the game folder.

The 32-bit Lua 5.1 compiler is required because Solar2D/Corona precompiled chunks are sensitive to bytecode format. Using the system `luac5.1` may produce a `bad header in precompiled chunk` error.

## Installation

Clone or copy this repository somewhere local.

Example:

```bash
cd /tmp/coromod
```

Make sure the script is executable:

```bash
chmod +x build_and_patch_coromon_32bit_luac.sh
```

Run it:

```bash
./build_and_patch_coromon_32bit_luac.sh
```

The script will create:

```text
.build/
.tools/
backups/
```

These are local build artifacts and should not be committed.

## Custom Steam Path

Default path:

```bash
~/snap/steam/common/.local/share/Steam/steamapps/common/Coromon/Resources/resource.car
```

Override only the `RESOURCE_CAR` path:

```bash
RESOURCE_CAR="/custom/path/Coromon/Resources/resource.car" ./build_and_patch_coromon_32bit_luac.sh
```

Or override the whole Steam apps directory:

```bash
STEAMAPPS="/custom/path/steamapps" ./build_and_patch_coromon_32bit_luac.sh
```

## Uninstall / Restore

The script creates a backup before replacing the game archive.

Backups are stored in:

```text
backups/
```

To restore:

```bash
cp -av backups/resource.car.backup.YYYY-MM-DD_HHMMSS \
"~/snap/steam/common/.local/share/Steam/steamapps/common/Coromon/Resources/resource.car"
```

Replace the backup filename with the actual one created by the script.

You can also restore the game through Steam by verifying/reinstalling the game files.

## Do Not Redistribute `resource.car`

Do not upload or redistribute the full patched `resource.car`.

That file contains original game data/code. The clean approach is to share only:

* The modified Lua source files in `mod/`.
* The build script.
* Instructions for users to rebuild their own patched archive locally.

## Troubleshooting

### `bad header in precompiled chunk`

This usually means the `.lu` file was compiled with an incompatible Lua compiler.

This script builds and uses a 32-bit Lua 5.1 compiler to avoid that issue.

### `resource.car not found`

Check your Coromon installation path.

For Snap Steam, the default is:

```bash
~/snap/steam/common/.local/share/Steam/steamapps/common/Coromon/Resources/resource.car
```

For other Linux Steam installations, pass the path manually:

```bash
RESOURCE_CAR="/path/to/Coromon/Resources/resource.car" ./build_and_patch_coromon_32bit_luac.sh
```

### The game crashes after patching

Restore the backup:

```bash
cp -av backups/resource.car.backup.YYYY-MM-DD_HHMMSS \
"/path/to/Coromon/Resources/resource.car"
```

Then check that your modified Lua files are valid and compatible with your current Coromon version.
