# Wandering Sword · Full-Map Teleport MOD (TeleportMod)

[中文](./README.md) | English

A full-map teleport mod for Wandering Sword (逸剑风云决) built on [UE4SS](https://github.com/UE4SS-RE/RE-UE4SS). It mounts as a Lua script without modifying the game's own files: type pinyin in the console to teleport across all 258 maps, or click in the courier-station UI to travel directly to the 92 major world-map locations.

## Features

- **F1 console pinyin teleport**: all 258 maps reachable (including test maps and forbidden zones), case-insensitive
- **Prefix fast travel**: for the 92 major world-map locations, the first two syllables are enough, e.g. 十万大山 → `shiwan`
- **tpm keyword search**: when you cannot recall the pinyin, look up place names by Chinese keyword, e.g. `tpm 万`
- **F2 courier-station UI**: reuses the game's native courier-station UI; select an entry to teleport
- **tomap \<ID\>**: teleport directly by map ID
- **F8 / tpfav** (debug-oriented): brings up the game's GM command UI and probes affinity data structures

## Requirements

- Wandering Sword PC edition (Unreal Engine 4.26)
- UE4SS experimental v3.0.1-944 (zDEV/EXPERIMENTAL build)

## Installation

1. Put `dwmapi.dll` and the `ue4ss` folder into `<GameDir>\Binaries\Win64` (overwrite if they already exist)
2. Launch the game — no extra configuration needed
3. To uninstall: delete `dwmapi.dll` and the `ue4ss` folder

## Usage

| Key / Command | Description |
| --- | --- |
| F1 | Open the console (input box at the bottom of the screen) |
| `pinyin` + Enter | Teleport to the corresponding map, e.g. `wutongcun` → 梧桐村 |
| `pinyin prefix` + Enter | For the 92 major locations, the first two syllables suffice, e.g. `shiwan` → 十万大山 |
| `tpm keyword` + Enter | Search place names by Chinese keyword |
| `tomap ID` + Enter | Teleport by map ID |
| F2 | Open the courier-station UI and click to travel |
| F8 | Bring up the game's GM command UI |

Notes:

- Three pairs of identically named places require the full pinyin (`pili` 霹雳岛/霹雳门, `tianshan` 天山/天山派, `wuxian` 五仙教/五仙岭)
- Full pinyin can reach forbidden zones and skip story triggers, which may affect normal progression — use at your own discretion
- If the screen occasionally goes black after a teleport, simply teleport once more to recover

## Directory Layout

```
mod/TeleportMod/Scripts/   Mod source code (Lua)
tools/                     Data-generation, deployment, and packaging scripts
extracted/                 Parsed game-data artifacts and the UE4SS runtime (runtime not committed)
发布/                       Local release packaging output (not committed)
```

## Development Tools (tools/)

| Script | Purpose |
| --- | --- |
| `parse_maps.py` / `parse_maps2.py` | Parse the game's map tables |
| `parse_courier.py` | Parse courier-station teleport-point data |
| `gen_maps_names.py` | Generate map ID ↔ Chinese-name mappings |
| `gen_pinyin.py` / `gen_maps_cmd.py` | Generate place-name pinyin and teleport-command data |
| `gen_bigmap.py` / `gen_final_bigmap.py` / `gen_map_maps.py` | Generate world-map major-location data |
| `gen_maps_path.py` | Generate map path data |
| `gen_mod_readme.py` / `gen_mod_readme_txt.py` | Generate user documentation |
| `install_mod.py` / `replace_ue4ss.py` | Deploy the mod and UE4SS into the game directory |
| `check_lua.py` | Lua syntax checking |
| `package_release.py` | One-click release packaging |

## Repository Notes

The following are large in size or regenerable and are therefore not tracked in version control (see `.gitignore`):

- `extracted/UE4SS*/`: third-party UE4SS runtime — download it from the [UE4SS Releases](https://github.com/UE4SS-RE/RE-UE4SS/releases) page
- `tools/*.zip`: original UE4SS archives
- `tools/*.bin`: intermediate artifacts of game-data decoding
- `发布/`: release packaging output; rebuild with `python tools/package_release.py`

## Acknowledgements

- [UE4SS-RE/RE-UE4SS](https://github.com/UE4SS-RE/RE-UE4SS) — the Lua scripting injection framework for Unreal Engine
- The Wandering Sword development team
