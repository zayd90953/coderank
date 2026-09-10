# CodeRank Developer Diary

## Session 1
Date: 30 July 2026

- Flutter installed
- GitHub created
- First project created

---

## Session 2
Date: 3 August 2026

Completed:
✅ App icon
✅ App name
✅ Branding
✅ Theme
✅ Splash Screen
✅ Animated Splash
✅ Folder Structure
✅ GitHub Push

Learned:
- Flutter project structure
- Git workflow
- Assets
- AnimationController
- Tween
- Hot Reload vs Hot Restart

Problems Solved:
- pubspec.yaml typo
- Asset loading issue
- SplashScreen widget error

Next Session:
- Onboarding
- Login UI
- Navigation

---

## Session 3
Date: 7 August 2026

Completed:
✅ Google Sign-In core auth + account picker + disconnect (P1-1, P1-2)
✅ Mock Test screen — 45Q / 2hr timed mode (P1-3a)
✅ Bottom nav hidden on auth screens (P1-4)
✅ Dark mode on login screens (P1-5)
✅ Android scrolling screenshot support (P1-6)
✅ Back gesture exits app (P1-7)
✅ QUESTION_SCHEMA.md + CODERANK.md master checklist written

Learned:
- Firebase auth providers and credential flow
- SharedPreferences for local persistence
- Timed question flows (per-question timers, auto-submit)

Problems Solved:
- Question palette RangeError on 45-question lists (regression test added)

Next Session:
- Home & Profile rework (P2)

---

## Session 4
Date: 11 August 2026

Completed:
✅ Home screen rework — congestion, badges, rank label (P2-1)
✅ Profile rework — avatars, settings sections, Firebase auto-fill (P2-2)
✅ P4-1..P4-6 regression fixes (routing, dead buttons, back navigation, exit dialog, error styling, settings audit)

Problems Solved:
- P2-1/P2-2 scope-creep regression → added the "audit before redesigning" hard rule

Next Session:
- Design system + A-phase

---

## Session 5
Date: 3 September 2026

Completed:
✅ A-1 design system (core/design tokens + ThemeData)
✅ A-2 dark-mode onboarding image blending
✅ A-3 Daily NEET Challenge — date-seeded 10Q, 45s/question, +50 XP, per-day lock
✅ A-4 Mock test modes — Full-Length (180Q/3hr) vs Quick (45Q/2hr) with chooser
✅ A-5 Performance Analytics — trend strip, focus callout, trending pills

Learned:
- Seeded shuffling for deterministic question sets
- Theme tokens vs hardcoded colors

Next Session:
- A-6 Practice Hub redesign

---

## Session 6
Date: 6–8 September 2026

Completed (audit & maintenance phase):
✅ Fixed 9 compile errors in profile sheets (sheet-chrome context param)
✅ Onboarding assets migrated .png → .jpeg, all asset references verified
✅ All analyzer warnings cleared; sign-in dark background regression restored
✅ Daily-challenge finish path guarded (persistence try/catch)
✅ Question bank JSON parsed once per run (static cache)
✅ Edit-name sheet: keyboard fix, controller lifecycle, example-name hint removed
✅ Native launch splash unified to brand green — purple boot screen removed
✅ Splash redesigned (bubbles, elastic logo bounce) + launcher icons regenerated
✅ Contrast fixes: settings tiles, mock-test landing heroes
✅ Mock-test top-bar overflow fix

Problems Solved:
- Two launch screens (purple native + green Flutter) → one green splash
- White boxes / invisible text in settings and mock-test heroes

Next Session:
- Full dynamic theming

---

## Session 7
Date: 9 September 2026

Completed:
✅ App-wide dynamic theming — light is default, dark optional (System/Light/Dark picker)
✅ 40+ screens migrated off hardcoded dark tokens to theme-derived colors
✅ Light/dark regression tests added (15/15 passing)
✅ Launch crash fixed — splash used SingleTickerProviderStateMixin with two controllers (red screen on device)
✅ 10 layout overflows fixed (welcome, sign-in, analytics, profile), found via phone-size smoke test across 12 screens

Learned:
- TickerProviderStateMixin vs SingleTickerProviderStateMixin
- Sheets must read MediaQuery viewInsets from the sheet's own builder context
- Flexible + ellipsis overflow-proofing for Rows with fixed-width siblings
- Test fonts inflate text width — smoke-test at real phone dimensions to catch overflows early

Next Session:
- A-6 Practice Hub redesign (CODERANK.md); audit leftovers: duplicate questions, streak-on-open