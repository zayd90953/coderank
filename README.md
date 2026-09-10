# CodeRank

A gamified NEET exam-prep app built with Flutter and Firebase. Practice subject-wise questions, take full-length and quick mock tests, complete the daily challenge, and track performance analytics — with XP, streaks, and a leaderboard.

## Features

- **Practice** — subject-wise question practice with configurable question counts and modes
- **Mock Tests** — Full-Length (180Q / 3hr, exam simulation) and Quick (45Q / 2hr) modes
- **Daily Challenge** — 10 date-seeded questions per day with a per-question timer and completion bonus
- **Performance Analytics** — accuracy trends, subject mastery, weekly focus areas
- **Gamification** — XP, streaks, leaderboard, profile avatars
- **Auth** — Google Sign-In and email/password via Firebase
- **Theming** — light (default) and dark modes, user-selectable in settings

## Tech Stack

- **Flutter / Dart** — UI framework
- **Firebase** — Auth, Firestore (user data, sessions, leaderboard)
- **google_sign_in** — Google authentication
- **shared_preferences** — local persistence (theme, streaks, daily-challenge lock)
- **flutter_native_splash / flutter_launcher_icons** — branding tooling

## Project Structure

```
lib/
├── main.dart              # App entry (Firebase init, splash)
├── app/                   # App widget, auth gate, theme
├── core/
│   ├── constants/         # Legacy color/style constants
│   └── design/            # Design tokens (AppColors, typography, ThemeData)
├── features/
│   ├── splash/            # Animated launch screen
│   ├── onboarding/        # First-run onboarding
│   ├── auth/              # Welcome + sign-in screens
│   ├── home/              # Home tab
│   ├── practice/          # Practice hub, setup, question, results
│   ├── mock_test/         # Chooser, landing screens, question flow, results
│   ├── daily_challenge/   # Daily 10Q challenge flow
│   ├── analytics/         # Performance analytics tab
│   ├── leaderboard/       # Leaderboard tab
│   └── profile/           # Profile tab, settings, sheets
├── shared/
│   ├── services/          # AuthService, UserPreferencesService, Firestore
│   └── widgets/           # Shared widgets (back button, exit dialog, ...)
└── data/                  # Question bank JSON (2,500 questions)
```

## Getting Started

1. **Prerequisites:** Flutter SDK, an Android/iOS device or emulator.
2. **Install dependencies:**
   ```bash
   flutter pub get
   ```
3. **Firebase setup (required before running):** add this project to a Firebase console project and place the generated `android/app/google-services.json` (and iOS config, if targeting iOS) — Google Sign-In needs a valid Android OAuth client in that file.
4. **Run:**
   ```bash
   flutter run
   ```

## Development

- `flutter analyze` — static analysis
- `flutter test` — test suite
- Question bank schema: see `QUESTION_SCHEMA.md`
- Project roadmap and conventions: see `CODERANK.md`
