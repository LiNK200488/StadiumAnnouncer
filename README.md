# Stadium Announcer

Stadium Announcer brings Pokémon Stadium-style battle commentary to Pokémon Red in [Gen1Recomp](https://github.com/bryanthaboi/gen1recomp) mod builds that provide the Gen1Recomp mod API used by this project.

Version: **1.0.3**

## Features

- Pokémon Stadium announcer voice lines during battles.
- Gym Leader, Elite Four, and Champion encounter introductions.
- Pokémon send-out calls for all 151 Generation I species.
- Move-name commentary for the Generation I move set.
- Reactions for critical hits, super-effective and not-very-effective damage.
- Status-condition commentary.
- Faint and victory commentary.
- Occasional battle-flow commentary.
- Optional idle commentary when the player remains on a battle decision screen.
- Configurable battle scope.

This mod contains announcer audio only. It does **not** include Stadium battle effects, 3D models, arenas, cameras, trainer portraits, ROM extraction, model/texture caches, or a cache builder.

## Installation

1. Download the `StadiumAnnouncer-v1.0.3.zip` release asset.
2. Install it as a Gen1Recomp mod using the same method you use for other Gen1Recomp mods.
3. Enable **Stadium Announcer** in the mod list.
4. Start Pokémon Red and open the mod options if you want to change the announcer scope.

The release archive retains this structure:

```text
StadiumAnnouncer/
├── manifest.json
├── main.lua
├── lib/
│   └── Announcer.lua
└── assets/
    └── announcer/
        ├── voicepack.json
        ├── 000.wav
        ├── ...
        └── 822.wav
```

## Options

**STADIUM ANNOUNCER** enables or disables announcer playback.

**ANNOUNCER BATTLES** controls where the announcer is active:

- `GYM / ELITE 4 / CHAMPION` — default; only major boss battles.
- `ALL TRAINER BATTLES` — all trainer battles.
- `ALL BATTLES` — trainer and wild battles.

## Compatibility

- Mod ID: `STADIUM_ANNOUNCER`
- Mod API: `2`
- Declared game compatibility: `0.0.0-dev || >=0.1.37 <2.0.0`
- Conflicts with `STADIUM_BATTLE_FX`, which contains overlapping announcer functionality.

Stadium Announcer is deliberately focused on audio and does not modify battle rendering, Pokémon sprites, move animations, arenas, or the battle HUD.

## Audio pack

The **v1.0.3 release package includes 823 announcer WAV files** (`000.wav` through `822.wav`). They are mono 16-bit PCM at 16 kHz.

The source code is licensed under the MIT License. The bundled Pokémon Stadium audio is **not covered by the MIT License**. See [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) before redistributing the audio assets.

## Development

The runtime entry point is `main.lua`. Announcer behavior lives in `lib/Announcer.lua` and uses Gen1Recomp battle events rather than move-specific patches.

The voice pack is described by `assets/announcer/voicepack.json`. The runtime verifies the pack marker and loads numbered WAV files on demand.

## License

The Stadium Announcer source code is available under the [MIT License](LICENSE).
