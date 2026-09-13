## v1.0.15 - deterministic Gen 2 mechanics

- Added presentation-synchronized Perish Song start/count-one commentary.
- Added Safeguard start/protection/end commentary.
- Added Spikes setup commentary.
- Added Future Sight setup and delayed-hit commentary.
- Added Mean Look trapping commentary.
- Added Disable success/end commentary.
- All new lines trigger from exact Gen 2 UI battle text; no fixed delays or raw engine-time playback were added.
- Gen 2 audio remains at the original 1.00x volume. Gen 1 is unchanged.

## v1.0.14 deterministic mechanics

Recovery/screens/setup commentary is synchronized to the Gen 2 UI message queue. Light Screen and Reflect are keyed by their move IDs because their result text intentionally looks like ordinary SPCL.DEF/DEFENSE stat-rise text. Substitute-break commentary keys from the exact `SUBSTITUTE broke!` message.

# Gen 2 clean runtime rebuild — v1.0.7

The Gen 2 announcer runtime was rewritten rather than incrementally patched.

Foundational fixes in the clean implementation:

- Uses the actual Stadium 2 pack size: 1,387 clips.
- Uses the actual four-digit filenames (`0000.wav` … `1386.wav`).
- Validates both `voicepack.json` and a real known WAV before reporting the pack ready.
- Normalizes Gen 2 engine-vs-UI battle objects before matching events.
- Ignores duplicate `battle.started` notifications for the same battle instead of resetting playback.
- Starts playback immediately from event handlers; `input.step` is only needed to advance queued clips after one finishes.
- Removes Gen 1 UI timing/deferred-action assumptions from the Gen 2 runtime.
- Gives every eligible Gen 2 trainer battle an immediate startup announcer sound (enemy species if resolvable, otherwise clip 0836) so a healthy install cannot remain completely silent.
- Move, switch, critical-hit, effectiveness, status, faint and generic battle-end sounds are all wired through normalized Gen 2 events.
- Leaves `Gen1Announcer.lua` unchanged.
