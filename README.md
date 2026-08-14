# React

React is a fast, phone-native reaction game built with Flutter and Flame.

## Current state

The project now includes playable implementations for:

- Classic — three lives with a gradually increasing pace
- Blitz — 60-second score attack with a time penalty for misses
- Endless — one miss ends the run, with an aggressive speed and visual-intensity ramp
- Daily — deterministic 60-command challenge with unlimited retries each day and one of seven gameplay modifiers
- Pass It — 2–4 player local multiplayer where the current player keeps clearing commands until a miss costs one life and hands the phone to the next living player; last player standing wins

Daily uses a deterministic Monday-to-Sunday deck so all seven modifiers appear exactly once per calendar week in a shuffled order:

- Lights Out — commands vanish after 650 ms
- Surge — recurring three-command rapid-fire bursts
- No Clock — no numeric countdown or timer ring
- Echo — every sixth clear repeats the command
- Reverse — directional swipes must be performed in the opposite direction
- Chain — almost no transition gap between commands
- Redline — every tenth command gets a sharply reduced reaction window

Every retry on the same calendar day keeps the same fixed challenge seed and modifier. Daily history keeps the strongest score for that day, streak progress advances at most once per calendar day, Results comparisons only compare against another run from the same day, and Daily new-best feedback is based on the active modifier rather than an unrelated Daily rule.

Debug builds expose a Daily developer tester so each modifier can be launched repeatedly without changing normal Daily history, streaks or records. The tester is not exposed in release UI.

The active command pool is:

- Tap
- Double Tap
- Hold
- Swipe Left
- Swipe Right
- Swipe Up
- Swipe Down
- Pinch
- Spread

Freeze, tilt, rotate and accelerometer-driven commands are not part of the active game.

## Architecture

Flutter owns navigation, HUDs, gesture input and mode setup screens. Flame owns the live gameplay visual layer, including ambient particles, success/miss bursts, pulse rings and pressure effects that intensify in faster modes.

Classic, Blitz, Endless and Pass It use the shared run engine. Daily has a dedicated controller because its seven rotating modifiers alter command visibility, expected input, timing and transition behaviour while still reusing the shared gesture surface, Flame layer, audio layer and Results model.

Pass It keeps match-wide score/stat totals separate from its per-turn difficulty ramp. Successful commands increase only the current player's turn pace; after a lost life and handoff, the next player starts from the normal Pass It reaction window rather than inheriting the previous player's accelerated pace.

Results provide mode-aware run summaries, previous-run comparisons where the data is meaningfully comparable, replay navigation, and a share flow for normal runs. Share Result opens a dedicated branded preview and exports the card as a 1080×1350 PNG through the platform share sheet. Developer Daily test runs are intentionally excluded from sharing.

## Local data

Until the online backend is introduced, SharedPreferences stores:

- Personal best scores for scored modes
- Total and per-mode runs played
- Successful-command totals
- Average reaction-time aggregates
- Per-command attempts, successes, misses and successful reaction-time totals
- Recent run history
- Daily played-today state and streak
- Daily history with modifier, strongest score and outcome for each recorded day
- Per-modifier Daily best scores
- Pass It player-count preference
- Sound preference
- Visual-effects preference
- Debug-only Daily modifier override preference

The Profile screen exposes Command Performance and Milestones views. Command Performance shows accuracy and average successful reaction time for every active command. Milestones are calculated entirely from real local records such as commands cleared, mode bests, Daily streaks and completed Pass It matches; there is no XP, level or currency system. The Daily screen shows the current Monday-to-Sunday modifier/result strip. No fake global ranks or online statistics are shown in the current offline build.

## Settings

The Profile / Settings screen exposes local records plus persisted Sound and Visual Effects toggles. Visual Effects directly control Flame rendering. The sound controller is centralized and currently uses temporary platform system sounds so gameplay cues can be tested before the final sound pack is chosen.

Reset Local Progress clears scores, run aggregates, command performance, recent history, Daily history/streaks and modifier records while preserving game settings.

## Visual direction

- Deep navy / near-black background
- Electric blue primary interaction colour
- Lime success and score accents
- Purple progression accents
- Coral-red failure and urgency accents
- Circular command / timer arena
- Rounded dark panels with thin neon borders
- Minimal asset dependency
- No haptics

## Backend

Supabase/Firebase are intentionally not connected yet. Online identity, global leaderboards, seasons and authoritative Daily challenges will be added only after the local gameplay build is stable.
