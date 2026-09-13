# Differences from vanilla

Stadium Announcer changes battle audio presentation only.

- Adds spoken Pokémon Stadium / Stadium 2 announcer commentary during battles.
- Adds configurable scope for major battles, all trainer battles, or all battles.
- Adds no gameplay changes.
- Does not change move behavior, damage, stats, AI, encounters, maps, sprites,
  battle animations, HUD layout, or save data.
- Disabling the mod restores vanilla battle audio behavior.

## Generation-specific implementation

The mod is one package with separate Gen 1 and Gen 2 announcer modules selected
at runtime. Shared behavior is kept conceptually aligned, while presentation
synchronization remains generation-specific where the two battle UIs expose
different reliable state.

## Version 2 baseline

v2.0.0 promotes the runtime-confirmed v1.0.44 implementation without runtime
changes. It includes the current Gen 1 opening synchronization, Gen 2
replacement-send-out synchronization, short move-line recovery, randomized
commentary pools, Gen 2 volume treatment, and the temporarily disabled Gen 2
post-KO replacement flavor pool.
