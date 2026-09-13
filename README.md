Stadium Announcer

Bring the voice of Pokémon Stadium into Gen1Recomp.

Stadium Announcer adds spoken battle commentary to Pokémon battles, with generation-specific announcer audio and timing designed to follow the actual battle presentation.

Supported Games
Generation I
Pokémon Red
Pokémon Blue
Pokémon Yellow

Uses announcer audio from Pokémon Stadium.

Generation II
Pokémon Gold
Pokémon Silver
Pokémon Crystal

Uses announcer audio from Pokémon Stadium 2.

Features
Pokémon name announcements during send-outs.
Move-name commentary synchronized with battle presentation.
Reactions to critical hits and type effectiveness.
Commentary for misses and attacks with no effect.
Status-condition reactions.
Pokémon fainting commentary.
Victory and battle-result commentary.
Voluntary switch commentary.
Replacement Pokémon announcements.
Special introductions for Gym Leaders, Elite Four members, Champions, and other supported major trainers.
Gen 2 Rival and Team Rocket Executive introductions.
Commentary for many Gen 2 battle mechanics, including:
Stat changes
Recovery
Reflect and Light Screen
Substitute
Weather
Held items and berries
Ongoing status effects
One-hit KOs
Double KOs
Remaining Pokémon counts
Randomized commentary pools to reduce repetition.
Two-line commentary pools randomly choose their starting clip and then alternate.
Optional idle commentary when waiting on the battle decision screen.
Announcer Scope

The ANNOUNCER BATTLES option controls where commentary is active.

Gym / Elite 4 / Champion

The default setting.

Commentary is enabled for major battles. Gen 2 also includes supported Rival and Team Rocket Executive encounters.

All Trainer Battles

Enables the announcer for every trainer battle.

All Battles

Enables the announcer for both trainer and wild Pokémon battles.

Installation
Download the latest release from the Releases page.
Install StadiumAnnouncer-v2.0.0.zip as a Gen1Recomp mod.
Enable Stadium Announcer in the Mod Manager.
Configure ANNOUNCER BATTLES in the mod options if desired.
Version 2

Version 2 combines the mature Gen 1 and Gen 2 announcer implementations into one release.

The Gen 1 and Gen 2 battle interfaces behave differently, so Stadium Announcer uses separate generation-specific runtimes to keep Pokémon names, moves, reactions, and other commentary synchronized with what is actually happening on screen.

Compatibility
Mod ID: STADIUM_ANNOUNCER
Mod API: 2
Supports Gen 1 and Gen 2 games in Gen1Recomp.
Does not modify battle rules, damage calculations, AI, encounters, sprites, move animations, arenas, cameras, HUD layout, or save data.
No declared conflict with STADIUM_BATTLE_FX.
Audio

The mod includes:

823 Pokémon Stadium announcer clips.
1,387 Pokémon Stadium 2 announcer clips.
Development

The shared mod entry point is:

main.lua

Generation-specific announcer implementations are located in:

lib/
├── AnnouncerSelector.lua
├── Gen1Announcer.lua
└── Gen2Announcer.lua

AnnouncerSelector.lua automatically selects the appropriate announcer implementation for the currently running game.

License

The Stadium Announcer source code is available under the MIT License.

Bundled Pokémon Stadium and Pokémon Stadium 2 audio is not covered by the MIT License.

See THIRD_PARTY_NOTICES.md for additional information.

Pokémon, Pokémon Stadium, Pokémon Stadium 2, character names, game audio, and related intellectual property belong to their respective rights holders.

This is an unofficial fan project and is not affiliated with or endorsed by Nintendo, The Pokémon Company, Creatures Inc., or Game Freak.
