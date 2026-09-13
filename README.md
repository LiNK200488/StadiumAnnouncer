# Stadium Announcer

Stadium Announcer adds Pokémon Stadium-style spoken battle commentary to
[Gen1Recomp](https://github.com/bryanthaboi/gen1recomp).

Version: **2.0.0**

The mod is generation-aware:

- **Red / Blue / Yellow:** Pokémon Stadium announcer audio.
- **Gold / Silver / Crystal:** Pokémon Stadium 2 announcer audio.

## Features

- Pokémon-name calls when battlers are presented.
- Move-name commentary synchronized to the visible move presentation.
- First-move and battle-flow commentary.
- Critical-hit, effectiveness, miss, immunity, status, faint, and battle-result reactions.
- Voluntary-switch commentary and synchronized replacement Pokémon name calls.
- Gym Leader / Elite Four / Champion introductions, plus supported Gen 2 rival and Team Rocket Executive intros.
- Gen 2 commentary for supported battle mechanics such as stat changes, recovery, screens, Substitute, weather, held items, ongoing status effects, one-hit KOs, double KOs, and exact remaining-team counts.
- Optional 10-second decision-screen idle commentary.
- Randomized interchangeable commentary pools. Two-clip pools start randomly and then alternate; larger pools randomize without immediate repeats.
- Configurable battle scope.

The mod changes battle audio presentation only. It does **not** modify battle
rules, damage, AI, encounters, sprites, move animations, arenas, cameras, HUD
layout, or save data.

## Installation

1. Download the release ZIP.
2. Install it as a Gen1Recomp mod using the same method as other content mods.
3. Enable **Stadium Announcer** in the mod list.
4. Open the mod options if you want to change where commentary is active.

The release archive contains this structure:

```text
StadiumAnnouncer/
├── manifest.json
├── main.lua
├── lib/
│   ├── AnnouncerSelector.lua
│   ├── Gen1Announcer.lua
│   └── Gen2Announcer.lua
└── assets/
    ├── gen1/
    │   ├── voicepack.json
    │   ├── 000.wav
    │   ├── ...
    │   └── 822.wav
    └── gen2/
        ├── voicepack.json
        ├── 0000.wav
        ├── ...
        └── 1386.wav
```

## Options

**ANNOUNCER BATTLES** controls where the announcer is active:

- `GYM / ELITE 4 / CHAMPION` — default. Gen 1 uses the supported major-battle set. Gen 2 also includes supported rival and Team Rocket Executive encounters.
- `ALL TRAINER BATTLES` — all trainer battles.
- `ALL BATTLES` — trainer and wild battles.

There is no separate announcer on/off option inside the mod: enable or disable
the mod itself in the Mod Manager.

## Version 2 baseline

v2.0.0 promotes the runtime-confirmed v1.0.44 build without changing announcer
behavior. Important fixes retained in this baseline include:

- Gen 1 render-side opening enemy-name synchronization.
- Gen 2 replacement Pokémon names waiting for the actual replacement send-out.
- Gen 2 short move-line synchronization for moves such as Protect and Spikes,
  so a missed short presentation cannot suppress later move announcements.
- Gen 2 announcer audio with the existing baked +25% WAV gain plus an additional
  1.25x runtime sample gain.
- The Gen 2 post-KO replacement flavor pool (`1156`–`1161`) intentionally remains
  disabled for a future pass; replacement Pokémon species-name calls remain active.

## Compatibility

- Mod ID: `STADIUM_ANNOUNCER`
- Mod API: `2`
- Declared game compatibility: `0.0.0-dev || >=0.1.37 <2.0.0`
- Supported engine generations: Gen 1 and Gen 2
- Declared mod conflicts: none

## Audio packs

The release package contains **823 Pokémon Stadium clips** in `assets/gen1` and
**1,387 Pokémon Stadium 2 clips** in `assets/gen2`.

The source code is licensed under the MIT License. The bundled game audio is
**not covered by the MIT License**. See
[THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) before redistributing the audio
assets.

## Development

`main.lua` owns the shared event subscriptions and option definition.
`lib/AnnouncerSelector.lua` selects the generation-specific runtime:

- `lib/Gen1Announcer.lua` for Red / Blue / Yellow.
- `lib/Gen2Announcer.lua` for Gold / Silver / Crystal.

Generation-specific presentation seams intentionally remain separate where the
two battle UIs behave differently.

## License

The Stadium Announcer source code is available under the [MIT License](LICENSE).

Pokémon, Pokémon Stadium, Pokémon Stadium 2, character names, game audio, and
related intellectual property belong to their respective rights holders. This
is an unofficial fan project and is not affiliated with or endorsed by
Nintendo, The Pokémon Company, Creatures Inc., or Game Freak.
