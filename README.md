# React

React is a fast, phone-native reaction game built with Flutter and Flame.

## Current milestone

The repository currently contains the app source baseline and the visual shell for:

1. Home
2. Classic
3. Results

Gesture recognition, sensors, scoring rules, persistence, leaderboards, audio, and backend services are intentionally out of scope for this milestone.

## Visual direction

- Deep navy / near-black background
- Electric blue primary interaction colour
- Lime success and score accents
- Purple progression accents
- Coral-red failure and urgency accents
- Glowing circular command / timer area
- Rounded dark panels with thin neon borders
- Minimal asset dependency

## Local platform bootstrap

This repository starts with the Flutter/Dart source baseline. On a machine with Flutter installed, generate the native runner folders once from the repository root:

```bash
flutter create --platforms=android,ios .
flutter pub get
flutter run
```

Do not overwrite the `lib/` source when reviewing generated changes.
