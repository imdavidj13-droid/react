# React

React is a fast, phone-native reaction game built with Flutter and Flame.

## Current state

The project now includes playable first-pass implementations for:

- Classic — three lives with a gradually increasing pace
- Blitz — 60-second score attack with a time penalty for misses
- Endless — one miss ends the run, with an aggressive speed and visual-intensity ramp
- Daily — deterministic 20-command local challenge with one attempt per day
- Pass It — three-player local multiplayer with handoff states and individual lives

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

Gameplay uses one shared run engine and one shared raw-pointer gesture surface so input behaviour stays consistent across modes.

## Local data

Until the online backend is introduced, SharedPreferences stores:

- Personal best scores
- Runs played
- Daily attempt state
- Daily streak
- Sound preference
- Visual-effects preference

No fake global ranks or online statistics are shown in the current offline build.

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
