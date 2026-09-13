# Stadium Announcer v2.0.0 — Known-good Version 2 baseline

This release promotes the runtime-confirmed v1.0.44 build to Version 2.0.0 without changing announcer behavior. Gen 1 and Gen 2 retain the same timing, mappings, random commentary behavior, options, and audio assets as v1.0.44.

The Version 2 baseline includes the confirmed Gen 2 replacement send-out synchronization, short move-line synchronization for moves such as Protect and Spikes, the Gen 2 runtime volume boost, and the intentionally disabled post-KO replacement commentary pool.

# Stadium Announcer v1.0.44 — Gen 2 short move-line synchronization

Some short Gen 2 status moves can present their `used MOVE` line between the mod's pre-update `input.step` samples. Protect and Spikes are examples: if that line was missed, the old pending-move queue could leave that move stuck at its head, which then prevented later move-name calls from matching even though later attacks were being shown normally.

v1.0.44 keeps the existing engine-time move event only as an early arm, but also latches the actual rendered `used MOVE` line from `battle.overlay` and consumes it on the next logic tick. A recovery path also matches later rendered move lines against the ordered pending queue so a single missed seam cannot poison subsequent announcements. No audio queue is changed from the draw hook itself.

Gen 1 runtime is unchanged. The v1.0.41 replacement Pokémon naming fix, v1.0.42 Gen 2 runtime volume boost, and v1.0.43 disabled post-KO replacement pool are all preserved. All WAV assets are unchanged.

# Stadium Announcer v1.0.43 — Disable Gen 2 post-KO replacement pool

The Gen 2 post-KO replacement commentary pool (`1156`–`1161`) is temporarily disabled. Its pool definition and enqueue block remain in `Gen2Announcer.lua` as commented code so the feature can be brought back later without losing the known implementation context.

This only removes those replacement flavor lines. Normal faint commentary, exact remaining-team commentary, the corrected replacement Pokémon species-name timing from v1.0.41, and the Gen 2 runtime volume boost from v1.0.42 are unchanged. Gen 1 and all WAV assets are untouched.

# Stadium Announcer v1.0.42 — Gen 2 runtime announcer gain

Gen 2 announcer playback now gets an additional `1.25x` gain in code. LÖVE's per-source volume cannot be raised above normal (`1.0`), so the mod applies the extra gain to the decoded sample data immediately before creating the audio source, with hard clamping at the valid sample range. The packaged WAV files are untouched.

This stacks on top of the existing +25% gain already baked into the Gen 2 WAV assets. Gen 1, battle timing, mappings, random commentary behavior, and the v1.0.41 replacement send-out synchronization are unchanged.

# Stadium Announcer v1.0.41 — Gen 2 replacement send-out sync

Gen 2's engine resolves the battle turn before its UI finishes presenting it. That meant `battle.battler_switched` could already point at a trainer's second Pokémon while the first Pokémon was still on-screen, and the old announcer gate mistook the existing enemy HUD for the new Pokémon being ready.

v1.0.41 keeps the engine event only as an early arm. A mid-battle species name is now released only after the Gen 2 UI reaches the matching send-out, then finishes its send-out animation/cry and raises that side's HUD. This fixes post-KO replacements and also makes voluntary switch naming obey the same presentation rule. Gen 1 and all audio assets are unchanged from v1.0.39.

This build is based directly on v1.0.39; the discarded v1.0.40 shared-core refactor is not included.

# Stadium Announcer v1.0.39 — Remove obsolete mod conflict

The obsolete `STADIUM_BATTLE_FX` conflict declaration has been removed from the manifest. This is a packaging/compatibility change only: announcer runtime behavior, options, timing, mappings, and all audio assets are unchanged from v1.0.38.

# Stadium Announcer v1.0.38 — Random-start two-clip pools

Two-clip commentary pools now randomize only their starting point. If clip A is chosen first, the pool continues B → A → B; if clip B is chosen first, it continues A → B → A. Pools with three or more alternatives keep the v1.0.37 random/no-immediate-repeat behavior. Timing, option scope behavior, exact mappings, and audio assets are unchanged.

# Stadium Announcer v1.0.37 — Randomized commentary pools

All interchangeable commentary pools now select randomly instead of walking through a fixed cycle. Pools with three or more alternatives avoid only the immediately previous clip; two-clip pools are allowed to repeat, because forcing no-repeat there would recreate an A/B/A/B cycle. This applies to Gen 1 and Gen 2 battle-flow, first-move, switch, damage/reaction, KO, mechanics, weather, and status-flavor pools that previously used round-robin selection. Exact identity/context mappings remain deterministic, and the private announcer PRNG still does not touch battle randomness. Timing, scope options, and WAV assets are unchanged from v1.0.36.

# Stadium Announcer v1.0.36 — Random decision-idle commentary

The 10-second decision-idle comments now vary naturally in both generations instead of following a fixed rotation. Gen 1 randomly chooses from `0749`–`0751`; Gen 2 randomly chooses from `1062`–`1064`. The picker prevents the same line from playing twice in a row and uses its own private PRNG so announcer flavor cannot perturb battle randomness. Everything else remains unchanged from v1.0.35.

# Stadium Announcer v1.0.35 — Gen 2 Gen-1 flavor parity

This release closes the three remaining Gen 1 flavor gaps in the Gen 2 runtime without changing Gen 1 or any audio assets.

- **First move:** Stadium 2 `0836` / `0837` now plays on the first actual move presentation, followed by that move's normal name call.
- **Battle flow:** after every two presented moves, the announcer may use `1065`–`1071` once the battle has returned to a quiet player decision screen.
- **Decision idle:** after 10 seconds without input on the main battle or move menu, Stadium 2 rotates `1062`–`1064`. Cursor movement/input resets the timer; Party/Pack/other pushed screens are excluded.
- All existing v1.0.34 Gen 2 trainer intros, send-out synchronization, effectiveness/critical timing, mechanics, KO handling, and option scope behavior are preserved.
- Gen 1 remains byte-identical to v1.0.34. All 2,212 WAV assets remain byte-identical.

# v1.0.33 — Gen 2 named major-trainer intros

Gen 2 now recognizes the game's verified trainer class IDs and starts the matching Stadium 2 named encounter intro for Gym Leaders, Elite Four, Champion Lance, Red, the rival, and Team Rocket executives where an identity-safe line exists. The default major-trainer scope is now strict instead of treating every trainer as a major battle. Existing Gen 2 send-out timing remains authoritative: if a long intro is still speaking when the enemy is fully presented, the exact enemy Pokémon name supersedes it. Gen 1 and all audio assets are unchanged.

## v1.0.32 — Gen 1 render-side opening enemy sync

The Gen 1 opening enemy species call now waits on the battle's actual rendered presentation state via `battle.overlay`. Trainer/link battles and wild battles are handled without reading the bottom text, and audio is only released after the enemy's intro/send-out presentation is fully settled. Long Gen 1 Gym/Elite/Champion intro commentary now yields to that first enemy species call when necessary, so it cannot hold the name until both sides are already on-field. The player name uses the previously working real `sendingOut` flag path. Gen 2 and all WAV assets are unchanged from v1.0.27.

