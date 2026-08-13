# React

React is a fast, phone-native reaction game built with Flutter and Flame.

## Current state

The project now includes playable implementations for:

- Classic — three lives with a gradually increasing pace
- Blitz — 60-second score attack with a time penalty for misses
- Endless — one miss ends the run, with an aggressive speed and visual-intensity ramp
- Daily — deterministic 60-command challenge with one attempt per day and one of seven gameplay modifiers
- Pass It — 2–4 player local multiplayer where the current player keeps clearing commands until a miss costs one life and hands the phone to the next living player; last player standing wins

Daily uses a deterministic Monday-to-Sunday deck so all seven modifiers appear exactly once per calendar week in a shuffled order:

- Lights Out — commands vanish after 650 ms
- Surge — recurring three-command rapid-fire bursts
- No Clock — no numeric countdown or timer ring
- Echo — every sixth clear repeats the command
- Reverse — directional swipes must be performed in the opposite direction
- Chain — almost no transition gap between commands
- Redline — every tenth command gets a sharply reduced reaction window

Debug builds expose a Daily developer tester so each modifier can be launched repeatedly without consuming the real Daily attempt. The tester is not included in release UI.

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

## Local data

Until the online backend is introduced, SharedPreferences stores:

- Personal best scores for scored modes
- Total and per-mode runs played
- Successful-command totals
- Average reaction-time aggregates
- Per-command attempts, successes, misses and successful reaction-time totals
- Recent run history
- Daily attempt state and streak
- Rolling seven-day Daily history with modifier, score and outcome
- Pass It player-count preference
- Sound preference
- Visual-effects preference
- Debug-only Daily modifier override preference

The Profile screen exposes a Command Performance view with accuracy and average successful reaction time for every active command. The Daily screen shows a rolling seven-day modifier/result strip. No fake global ranks or online statistics are shown in the current offline build.

## Settings

The Profile / Settings screen exposes local records plus persisted Sound and Visual Effects toggles. Visual Effects directly control Flame rendering. The sound controller is centralized and ready for final audio assets, but placeholder sound effects are intentionally not bundled.

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
