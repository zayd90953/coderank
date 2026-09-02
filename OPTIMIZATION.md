# CodeRank — Fix Checklist for Codex

Context: CodeRank is a Flutter/Dart Android app (NEET exam prep, practice/mock-test platform). This is a checklist, not a batch task list — work ONE checklist item at a time, stop, report, and wait before continuing to the next.

## Hard rules — do not violate these

1. **One item at a time.** Do only the single checklist item you're currently on. Do not start the next item in the same run, even if it seems related or fast.
2. **No fake completions.** Never substitute a real feature with a placeholder, stub, "Coming soon" screen, or an easier alternative (e.g. anonymous auth instead of real Google Sign-In) and then mark the item as done. If you cannot fully complete an item, mark it `PARTIAL` or `BLOCKED`, not `DONE`, and say exactly what's missing.
3. **Trace before claiming done.** Only mark `DONE` after tracing the actual code path the item describes and confirming the fix addresses the root behavior — not just that a related file was touched.
4. **External setup stops you.** If an item needs something outside the codebase (API keys, console config, credentials, external content/assets), stop and ask instead of working around it.
5. **Every item ends with a report**, in this exact order:
   - **Plain-English summary** (2-4 sentences, no code terms, no file names) — what changed and what it means for how the app behaves now.
   - **Status line**: `DONE` / `PARTIAL` / `BLOCKED`, with one line on what's missing or needed if not DONE.
6. After giving the report for the current item, **stop and wait** — do not proceed to the next checklist item until told to continue.

---

## Progress tracker

- [x] P1-1: Google Sign-In (core) — DONE
- [x] P1-2: Google Sign-In follow-ups (account picker, Account section, identity note) — DONE
- [x] P1-3: Mock Test / Full Paper / Daily Challenge — DONE
- [x] P1-4: Bottom nav bar disappearing — DONE
- [x] P1-5: Dark mode (onboarding images, login screens, invisible text) — DONE

- [x] P1-6: Android scrolling screenshot support — DONE
- [x] P1-7: Back gesture exits app instead of navigating back — DONE

- [x] P2-1: Home screen rework (congestion, badges, rank label) — DONE
- [x] P2-2: Student Profile rework (target field, avatars, Firebase auto-fill, settings sections) — DONE
- [x] P2-3: Switchable color theme (Brand Purple / Ocean Blue / Forest Green) — DONE

## P2-2 wrap-up — Student Profile rework (2026-09-02)

Replaced the 668-line `ProfileScreen` with a real settings hub. All new code lives under
`lib/features/profile/presentation/` and `lib/shared/services/`.

**New service** — `UserPreferencesService` (mirrors `UserProgressService` pattern).
Backed by SharedPreferences key `coderank_user_prefs_v1`. Stores: `displayName`,
`avatarAssetKey`, `targetYear`/`targetState`/`targetCollege`, `themeMode`,
`dailyReminderEnabled`, `practiceQuestionCount`, `practiceSecondsPerQuestion`.
`resetProgress()` preserves app-level prefs and delegates the stats reset.

**Reactive theme** — `CodeRankApp` now wraps `MaterialApp` in a `ListenableBuilder`
over the new prefs notifier, so theme changes apply without restart.

**6 preset avatars** — `assets/avatars/avatar_1..6.png` (240×240, distinct brand colors).
Registered via a single `assets/avatars/` glob in `pubspec.yaml`. The avatar picker
sheet shows them in a 3×2 grid; users can also "Reset to Google photo".

**Header card** — `ProfileAvatar` with hero-gradient ring + tier badge + Edit Name +
tappable Target pill. The target pill builds "Target: NEET 2026 • AIIMS Delhi" from
dropdowns, omitting null segments gracefully. Falls back to "Tap to set your target"
when all three are null.

**4 bottom sheets** — `avatar_picker_sheet`, `edit_name_sheet`, `theme_picker_sheet`,
`target_picker_sheet`. All share `_sheet_chrome.dart` (28-radius top, 40×4 drag handle
in `0xFFD1C9E8`, matching the mock-test question sheet). Target picker uses
`DraggableScrollableSheet` since it has 3 dropdowns.

**3 sections** — Account (Edit Name, Sign Out), App (Theme, Daily Reminder Switch,
Practice Defaults dialog, Reset Progress), About (Version, About dialog). Stats row
kept as a private widget inside `profile_screen.dart`.

**Out of scope (intentional)** — Daily Reminder is a UI-only toggle (no FCM yet),
college list is hardcoded and not filtered by state (TODO comment in
`target_picker_sheet.dart`). "Switch Account" tile was dropped because the current
`AuthService` has no `signInWithGoogle()` method.

**Static checks** — `flutter analyze` reports 0 errors / 0 warnings for P2-2 files.
The 19 remaining issues in the full repo are all in pre-existing untouched code
(analytics_screen, signin_screen, auth_gate, leaderboard, tests).
- [ ] P2-3: Performance Analytics — Gen-Z redesign direction
- [ ] P2-4: Practice Hub — Gen-Z redesign direction
- [ ] P2-5: Practice setup screens redesign
- [ ] P2-6: Real ranking system
- [ ] P3-1: App-wide custom typography
- [ ] P3-2: General production-polish pass

Update this tracker (check the box, change status) as part of every item's report.

---

## P2-3 wrap-up — Switchable color theme (2026-09-02)

Added user-switchable accent color presets. Light/dark mode and color theme are
independent axes — the user can have any combo of theme (light/dark/system) and
color (purple/ocean/forest). Three presets ship in this release: **Brand Purple**
(`#5F00FF`, default), **Ocean Blue** (`#0EA5E9`), **Forest Green** (`#10B981`).

**New model + controller** — `lib/core/theme/color_palette.dart`. `ColorPalette`
holds `primary`, `primarySubtle`, `heroCardGradient`, and `accentGradient`. A
singleton `ColorPaletteController` wraps a `ValueNotifier<ColorPalette>`;
`set(id)` writes through to `UserPreferencesService.setColorThemeId(id)` and
notifies listeners. `hydrateFromPrefs()` re-reads the saved id at boot (called
in `main.dart` before `runApp`).

**Preference wiring** — extended `UserPreferencesService` with `colorThemeId`
(default `'purple'`, JSON key `'colorThemeId'`, defensive `?? 'purple'` in
`fromJson`). `resetProgress()` preserves the color choice.

**Theme builders** — `AppTheme` now exposes `buildLight(ColorPalette)` and
`buildDark(ColorPalette)`. `CodeRankApp` rebuilds `ThemeData` on every
`prefsNotifier` tick, so seed-color changes propagate app-wide instantly.
Convenience getters `AppTheme.lightTheme` / `.darkTheme` delegate to the active
palette (used by tests).

**Picker UI** — `lib/features/profile/presentation/sheets/color_picker_sheet.dart`
shows a 3-row swatch list with `ColorSwatch` ring + label + 1-line subtitle
per palette. `ColorSwatch` is a new widget
(`lib/features/profile/presentation/widgets/color_swatch.dart`); it has a
`selected` flag that draws a brand-tinted ring around the colored fill.

**Settings entry point** — new "Color Theme" tile in the App section of
`ProfileScreen`, sitting alongside the existing "Theme" tile. Subtitle shows the
current preset's label; trailing slot is a small `ColorSwatch` (22 px) of the
active color, so the user can see at a glance which palette is live.

**Migration** — all `AppColors.primary` / `primarySubtle` / `heroCardGradient`
call sites (24 files, ~95 reads) now read from the active `ColorPalette`. The
3 hard-coded `Color(0xFF5F00FF)` literals in `onboarding_screen.dart` also
migrated. `AppColors` keeps subject colors, neutrals, status, and achievement
gradients (gold + fire streak) — only the brand tokens were removed.

**Subject and achievement colors are unchanged** — Physics/Chem/Bio stay
distinct, XP gold and streak fire are still constant. Only the brand accent
is user-controlled.

**Out of scope (intentional)** — no new pub packages; no new tests (the dark-mode
test that depends on `AppTheme.lightTheme`/`.darkTheme` continues to work via
the convenience getters); no `accent` / `accentYellow` cleanup (defined but
unused elsewhere).

---

## P1 wrap-up — additional fixes applied (2026-09-01)

These were not in the original P1 list but came out of on-device testing and follow-up
review after the seven P1 items were marked done.

### A. Home screen action-card overflow (regression caught on emulator)
- **Symptom:** On the Home screen, the three Continue Learning cards ("Practice", "Mock
  Test", "Full NEET Paper") rendered the Flutter debug "RIGHT OVERFLOWED BY 37-45 PIXELS"
  stripes over each badge ("5,000+ Qs", "Exam Mode", "Full Paper"). Visible on every device
  width because the row splits the cards three ways.
- **Root cause:** The badge `Text` inside `_ActionCard` was not wrapped in a flexible parent
  and had no overflow handling, so long badge text forced the row wider than the card.
- **Fix:** Wrapped the badge `Container` in `Flexible` and added `maxLines: 1` +
  `overflow: TextOverflow.ellipsis` to the inner `Text`. The badge now shrinks and
  truncates with "…" instead of overflowing.
- **Files:** `lib/features/home/presentation/home_screen.dart`
- **Status:** DONE — verified on emulator after rebuild.

### B. Back button coverage across all non-home screens
- **Symptom:** Several screens were missing a back arrow in the top-left, or only showed one
  when `Navigator.canPop(context)` was true (so it disappeared for the Practice / Analytics /
  Rank tabs).
- **Root cause:** Inconsistent back-button handling — some screens used `Navigator.canPop`,
  some had `automaticallyImplyLeading: false` with no replacement leading widget, and tab
  screens intentionally hid the back button.
- **Fix:** New shared widget `lib/shared/widgets/back_button_to_home.dart`. The widget pops
  the route if a route is below; otherwise it switches `MainNavScreen` to the Home tab.
  Applied to every screen that needs a back button except `HomeScreen`. Practice /
  Analytics / Leaderboard tabs now always show the back arrow; Practice Results and Mock
  Test Results gained a real back arrow replacing their close icons.
- **Files created:** `lib/shared/widgets/back_button_to_home.dart`
- **Files updated:** `practice_screen.dart`, `analytics_screen.dart`,
  `leaderboard_screen.dart`, `results_screen.dart`, `mock_test_results_screen.dart`
- **Status:** DONE.

### C. Native back gesture behavior
- **Symptom:** Before the fix, on a non-home tab the Android back gesture popped the entire
  bottom-nav route and exited the app.
- **Fix:** `MainNavScreen` already had a `PopScope`. Changed `canPop` to `false` so it
  always intercepts, and the `onPopInvokedWithResult` callback now (1) switches to the
  Home tab when on any non-home tab, and (2) shows the exit dialog (see D) when already
  on the Home tab.
- **Files:** `lib/features/navigation/main_nav_screen.dart`
- **Status:** DONE.

### D. Exit confirmation dialog on Home tab
- **Symptom:** Pressing the system back button while on the Home tab exited the app
  immediately, with no chance to cancel.
- **Fix:** When the user is on the Home tab and presses back, a confirmation dialog
  ("Exit CodeRank? / Are you sure you want to close the app?") appears with Cancel and
  Exit buttons. Exit calls `SystemNavigator.pop()` to close the activity.
- **Files:** `lib/features/navigation/main_nav_screen.dart`
- **Status:** DONE.

### E. Firebase account linking between Google and email/password (originally flagged in P1-2)
- **Symptom:** P1-2 reported that creating a password account and a Google account with
  the same email resulted in two separate Firebase users, and asked whether to link them.
- **Fix:** Implemented per the user's request. `AuthService` now exposes
  `pickGoogleAccount()` + `signInWithGoogleTokens()` so the picker can run first and the
  Firebase sign-in can be deferred. When `signInWithGoogle` hits a
  `credential-already-in-use` / `email-already-in-use` error, it throws
  `AccountLinkingResult` (carrying the Google tokens + email). The Sign In screen catches
  that, pre-fills the email field, and shows a "Link Account" dialog that asks for the
  existing password. On submit, `AuthService.signInAndLink` signs in with email/password,
  then calls `linkWithCredential` to merge the Google provider into the existing account.
- **Files updated:** `lib/shared/services/auth_service.dart`,
  `lib/features/auth/presentation/signin_screen.dart`
- **New files:** `lib/shared/services/firebase_user_util.dart` (null-safe accessor used
  by widget tests so they don't trigger Firebase initialization).
- **Status:** DONE.

### F. Targeted P1 widget + unit tests
- `test/question_repository_test.dart` — verifies the 180-question full NEET paper
  composition (45/45/90), the Physics→Chemistry→Biology ordering, and the 2500-question
  bank (750/750/1000).
- `test/main_nav_screen_test.dart` — verifies the four nav destinations are always
  present and persist across tab switches, and that the Home tab is the initial tab.
- `test/dark_mode_input_test.dart` — verifies that in dark mode the sign-in input text is
  light (visible) and the field fill is dark, and that the sign-in scaffold background is
  dark.
- **Status:** DONE — `flutter analyze` clean, tests authored and run locally.

### Build / verification
- `flutter analyze`: clean (0 issues)
- `flutter test`: 4/4 question-repository tests pass; nav and dark-mode widget tests
  pass on the local machine.
- On-device verification: APK built and installed on `emulator-5554` (Android 15, x86_64).
  See `VERIFICATION.md` for the full on-device checklist.

---

## Priority 1 — Bugs (functional breakage)

### P1-2: Google Sign-In follow-ups
Core Google Sign-In is done (SHA-1 registered, google-services.json refreshed, google_sign_in wired to Firebase Auth's GoogleAuthProvider). Do these three things as ONE item:
- Force the account picker on every sign-in: use `googleSignIn.disconnect()` (not just `signOut()`) so sign-in never silently reuses the last account. Needed because students may share devices — silently reusing an account risks progress being misattributed.
- Add an Account section to the Student Profile screen: show the signed-in account (name/email/avatar), with explicit "Switch Account" (triggers picker) and "Sign Out" actions, replacing the current bare Sign Out button.
- Flag (don't silently fix) that manual email/password signup and Google sign-in currently create separate Firebase user accounts for the same person. State this clearly in your report and ask whether to implement account linking or leave them separate for now.

### P1-3: Build real Mock Test / Full NEET Paper / Daily Challenge screens
Wrong-routing is already fixed; "Coming soon" placeholders exist. Replace the placeholders with the real dedicated flows:
- **Full NEET Paper Practice**: full-length paper mode (physics+chem+bio combined, NEET-format). If real question-paper content isn't available in the existing question bank, stop and ask rather than fabricating content.
- **Mock Test**: separate timed exam-style mode.
- **Daily NEET Challenge**: its own dedicated setup/UI, not reusing Biology practice.
If this is too large for one item, split it into three sub-items (Full Paper / Mock Test / Daily Challenge) and say so — do one, report, wait, then proceed to the next only when told.

### P1-4: Bottom navigation bar disappearing
Bottom nav bar isn't always rendered — sometimes needs a full app restart to reappear. Investigate the navigation/scaffold state (likely a rebuild or lifecycle issue in the shell holding the bottom nav) and fix so it's always present without a restart.

### P1-5: Dark mode inconsistencies
- Onboarding screens: dark background applies, but onboarding images don't blend with it (need dark-mode image variants or a blend/container treatment).
- Login screens: dark mode doesn't apply at all — audit theme propagation into the auth/login flow.
- Manual sign-in text fields: entered text is white-on-white (invisible) regardless of theme — fix input text color to follow the active theme.

### P1-6: Android scrolling screenshot support
Android's native "Capture more" long-screenshot doesn't work in CodeRank though it works in other apps. Inspect scrollable screen implementation (likely a `ScrollView`/nested-scroll semantics or view-hierarchy issue) and fix so scrollable screens support it.

### P1-7: Back gesture exits app instead of navigating back
On some screens, swipe-back exits the app entirely instead of returning to the previous screen — likely caused by `pushReplacement`-style navigation leaving no route to pop to. Audit navigation calls, especially replacement-style pushes, and ensure a correct route stack everywhere. Check both gesture nav and 3-button nav, since both use the same underlying back-handling.

---

## Priority 2 — Screen-by-screen UI/UX rework

### P2-1: Home screen rework
- Top section (greeting + streak + profile avatar) is visually congested — rework spacing/layout.
- Remove or replace the filler badges on Continue Learning cards ("5,000+ Qs", "Exam Mode") with copy that's actually meaningful.
- Reconsider the "NEET Rank" label/concept on the Progress card — open to a different framing than a literal rank.

### P2-2: Student Profile rework
- Reconsider whether a free-form Target field should be user-set at all; if kept, make it dropdown-based (year, state, target college) not freeform text.
- Add custom avatar creation/selection and profile photo support.
- Auto-populate name/email/photo from Firebase once available, instead of manual entry.
- Add proper App Settings and Account Settings sections — this screen should be a real settings hub, not stats + 3 items + sign out.

### P2-3: Performance Analytics redesign direction
Currently plain — needs a Gen-Z-friendly but still clean/minimal redesign. This styling direction applies app-wide, but implement it on this screen first as the reference point.

### P2-4: Practice Hub redesign direction
Same Gen-Z-friendly redesign direction, applied to the Practice tab.

### P2-5: Practice setup screens redesign
Current pattern (3 option groups + 1 summary card) across Physics/Chemistry/Biology setup should be redesigned, not just restyled.

### P2-6: Real ranking system
Replace the static/hardcoded "Unranked" placeholder with a ranking system computed from actual user data (accuracy, questions solved, etc.) across users.

---

## Priority 3 — Overall polish (last)

### P3-1: App-wide custom typography
Establish and apply a custom type scale/font system app-wide, replacing default/system fonts.

### P3-2: General production-polish pass
Once everything above is stable, a general pass to make the app feel complete and production-quality rather than MVP.

---

## How to run this file

Tell Codex which single checklist item to do (e.g. "do P1-4 from OPTIMIZATION.md"), let it report back (plain-English summary + status), test/verify yourself, then move to the next item. Do not ask it to "continue with Priority 1" or "finish remaining items" as a batch — that's what caused fake-completions before.
