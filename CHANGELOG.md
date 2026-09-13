# 2.0.0 — Known-good Version 2 baseline

- Promotes runtime-confirmed v1.0.44 to the Version 2 baseline.
- No announcer behavior, timing, mappings, audio, or options changed from v1.0.44.
- Preserves Gen 2 short move-line synchronization, replacement send-out synchronization, runtime volume boost, and the disabled post-KO replacement pool.
- Gen 1 behavior remains unchanged.

# 1.0.44 — Gen 2 short move-line synchronization

- Fixes Gen 2 move-name announcements getting stuck after short status-move presentations such as Protect and Spikes.
- Adds a Gen 2 render-side `battle.overlay` latch that remembers the actual rendered `used MOVE` line and releases it on the next logic tick; audio queues are still never mutated during drawing.
- Adds ordered resynchronization so one genuinely missed short move line cannot remain at the head of `pendingMoves` and suppress later move announcements.
- Keeps the v1.0.41 replacement send-out timing fix, v1.0.42 Gen 2 runtime gain, v1.0.43 disabled post-KO pool, Gen 1 code, and all WAV assets unchanged.

# 1.0.43 — Disable Gen 2 post-KO replacement pool

- Temporarily disables the Gen 2 post-KO replacement commentary pool (`1156`–`1161`).
- Keeps both the pool definition and its enqueue wiring commented in `Gen2Announcer.lua` for a later timing/content pass.
- Faint commentary, remaining-team-count commentary, replacement Pokémon name timing, Gen 2 runtime gain, Gen 1 behavior, and all WAV assets remain unchanged from v1.0.42.

# 1.0.42 — Gen 2 runtime announcer gain

- Adds a Gen 2-only `1.25x` playback gain in code while each WAV is decoded.
- The gain is applied to the decoded sample values with explicit `-1..1` clamping; it does not alter the packaged WAV files.
- This is in addition to the existing +25% amplitude already baked into the Gen 2 WAV assets.
- Gen 1 playback, all announcer timing/mappings, the v1.0.41 replacement send-out fix, options, and every WAV asset remain unchanged.

# 1.0.41 — Gen 2 replacement send-out sync

- Fixes Gen 2 replacement Pokémon names being announced from the engine-time `battle.battler_switched` event while the fainted Pokémon was still visibly on the field.
- Mid-battle Gen 2 names now require the UI to actually arm the matching send-out (`pendingSendOut` / `afterSendOut`) and wait for that send-out animation, cry, and HUD reveal to finish before the species call is released.
- Applies the same presentation gate to voluntary mid-battle switches, preventing their new Pokémon name from using the outgoing Pokémon's still-visible HUD as a false ready signal.
- Opening Pokémon timing, KO commentary, trainer intros, Gen 1 runtime, options, mappings, and all WAV assets remain unchanged from v1.0.39.
- Corrects the exported runtime version string to `1.0.41`.

# 1.0.39 — Remove obsolete mod conflict

- Removes the manifest conflict with `STADIUM_BATTLE_FX`.
- Stadium Announcer no longer asks Mod Manager to block that mod from being enabled alongside it.
- No runtime logic, timing, commentary mappings, options, or WAV assets changed from v1.0.38.

# 1.0.38 — Random-start two-clip pools

- Two-clip interchangeable commentary pools now choose a random starting clip, then alternate between the two clips for the rest of that battle.
- This restores deterministic A/B alternation for two-choice pools without always making the same clip the first one heard.
- Pools with three or more clips remain random with no immediate repeat.
- Exact mappings, timing, scope behavior, private announcer PRNG isolation, and all WAV assets are unchanged from v1.0.37.

# 1.0.37 — Randomized commentary pools

- Replaces every fixed round-robin commentary rotation in both generations with random selection.
- Pools with three or more clips avoid an immediate repeat. Two-clip pools remain fully random, because forbidding repeats there would force an A/B/A/B cycle.
- Gen 1 now randomizes battle flow, first-move, player-switch, critical, effectiveness, and faint commentary pools.
- Gen 2 now randomizes battle flow plus all previously rotating switch, first-move, damage/reaction, KO/team-count, mechanics, weather, and ongoing-status pools.
- Exact mappings remain deterministic: Pokemon names, move names, trainer intros, status-specific lines, stat-strength-specific lines, and other context-specific single clips are unchanged.
- Commentary randomness uses the announcer's private PRNG and does not consume the game/battle RNG.
- Timing, option scope behavior, and all WAV assets are unchanged from v1.0.36.

# 1.0.36 — Random decision-idle commentary

- Gen 1 decision-idle lines (`0749`–`0751`) now choose randomly instead of cycling in fixed order.
- Gen 2 decision-idle lines (`1062`–`1064`) now choose randomly instead of cycling in fixed order.
- Immediate repeats are prevented in both generations.
- Idle-line randomness uses a private announcer PRNG and does not consume the game/battle RNG.
- All other announcer timing, option scope behavior, and WAV assets are unchanged from v1.0.35.

# 1.0.35 — Gen 2 Gen-1 flavor parity

- Adds Stadium 2 first-move commentary (`0836` / `0837`) at the proven live Gen 2 `used MOVE` presentation seam, immediately before the first move-name call.
- Adds Gen 1-style battle-flow commentary after every two presented moves, using Stadium 2's matching heated-battle pool (`1065`–`1071`) only after a quiet return to the player's decision screen.
- Adds the 10-second decision-idle commentary used by Gen 1, mapped to Stadium 2's matching stare/no-command lines (`1062`–`1064`). Moving the cursor or pressing input resets the timer, and pushed Party/Pack screens do not trigger it.
- Keeps all existing Gen 2 move/reaction/mechanics timing intact; flavor lines never queue behind active battle commentary.
- Gen 1 runtime and all WAV assets are unchanged from v1.0.34.

# 1.0.33 — Gen 2 named major-trainer intros

- Wires Stadium 2 encounter intros for all verified Johto/Kanto Gym Leaders, Elite Four, Champion Lance, and Red.
- Wires the generic Stadium 2 rival intro for RIVAL1/RIVAL2 and the generic Rocket executive intro when the selected scope includes those trainer battles.
- The default `GYM / ELITE 4 / CHAMPION` scope now uses Gen 2's verified major-trainer class set instead of falling back to every trainer battle.
- Stadium-specific Gym Leader Castle underling intros are intentionally not mapped onto unrelated Crystal trainers.
- Long trainer intros may be superseded by the enemy species-name call once the foe is actually presented, preserving the already-confirmed Gen 2 send-out synchronization.
- Gen 1 runtime and all WAV assets are unchanged from v1.0.32.

## 1.0.32 - Gen 1 render-side opening enemy sync

- Gen 1 opening enemy Pokemon names now synchronize from the `battle.overlay` render seam instead of polling intro text/queue flags.
- The release gate mirrors Gen1Recomp's own enemy presentation readiness: intro slide/balls finished, trainer slot clear when applicable, send-out/grow-in complete, and entrance cry/HUD hold complete.
- Wild openings use the same renderer-ready state and do not require an enemy trainer.
- If a long Gen 1 Gym/Elite/Champion intro clip is still playing when the enemy is actually presented, the opening enemy species call now supersedes that intro instead of waiting behind it.
- The player opening name uses the already-tested real `sendingOut` flag path from v1.0.28.
- Gen 2 runtime and all audio assets remain unchanged from v1.0.27.

