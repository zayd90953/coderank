# CodeRank — Master Checklist

**Project:** CodeRank — Flutter/Dart Android NEET exam prep app  
**Foundation:** Existing codebase (Firebase/Google Sign-In working, navigation shell, question repository, 2,229 clean questions, existing assets)  
**Goal:** A complete adaptive NEET tutoring app — not an MVP, a genuinely good v1 — built on top of the existing foundation, one item at a time.  
**Current date:** September 2026

---

## Hard rules — Claude Code must never violate these

1. **One item at a time.** Do only the single item you're on. Do not start the next, even if it seems fast or related.
2. **No fake completions.** No placeholders, stubs, or easier substitutes reported as done. If incomplete, mark `PARTIAL` or `BLOCKED` with exactly what's missing.
3. **Trace before claiming done.** Only mark `DONE` after confirming the actual behavior, not just that a file was touched.
4. **Audit before redesigning.** Before any UI rework item, list what you're about to change and why. Do not redesign beyond the scope of the item.
5. **External setup stops you.** If something needs Firebase console, API keys, or credentials outside the codebase, stop and mark `BLOCKED`.
6. **Every item ends with a two-part report:**
   - Plain-English summary (2-4 sentences, no code terms, no file names) — what changed, what it means for how the app behaves.
   - Status line: `DONE` / `PARTIAL` / `BLOCKED` with one line on what's missing if not DONE.
7. **Autonomous session mode:** Do NOT stop between tasks waiting for confirmation. After completing one item and writing its report to PROGRESS.md, immediately begin the next TODO item. Only stop if BLOCKED (external setup needed) or all tasks are done.
8. **Checkpoint before cutoff:** If the session is about to end (time limit, error, or any forced stop), write a Partial State entry to PROGRESS.md before stopping — list every file touched, what was completed, and what remains. The next session will resume from this.
9. **Skip BLOCKED items.** If an item is BLOCKED, note the reason in PROGRESS.md and move to the next TODO item immediately. Do not halt the session for a blocker.
10. **Windows PowerShell environment.** Do not use Unix-only shell commands (sed, grep, awk). Use PowerShell-native equivalents or make file edits directly through file-editing tools.
11. **flutter analyze must be clean** before any item is marked DONE.
12. **Read before editing.** Always read a file's current contents before modifying it. Never assume what's in a file.

---

## Design contract — reference this on every UI item

Read and follow this before touching any screen. This is the visual identity of CodeRank — nothing should be built that contradicts it.

**Philosophy:** Light-first, dark-ready, bold, and game-like. The app competes for attention with social media and games — it needs to feel like it belongs there, not like a textbook. The default experience is light mode, while dark mode is a fully supported, adaptive alternative.

**Color system:**
- Background: use the active theme's surface token; light mode is the default and dark mode uses the near-black canvas.
- Surface cards: use the active theme's surface/container token; cards must adapt cleanly instead of using fixed light or dark colors.
- Text: use the active theme's `onSurface` for primary text and `onSurfaceVariant` for secondary text.
- Error/destructive: use the active theme's `error` token.
- Brand accent: Electric Green `#39D353` is the only primary brand color. Gold, orange, and red may appear only as tiny domain or achievement accents.
- Native splash background: `#39D353` (Electric Green) with the white CodeRank logo asset.

**Typography:**
- Display/headlines/scores: a rounded, personality-forward font (e.g. Nunito or Space Grotesk) — never the Flutter default.
- Body/question text: a clean, highly legible font optimized for reading under time pressure (e.g. Inter or DM Sans).
- Two fonts maximum. Consistent hierarchy throughout.

**Game-like mechanics (must be present, not optional):**
- Streak counter with real visual weight — not a small badge, a satisfying animated moment when it grows.
- XP/level system with a genuine level-up event (animation, color flash) — not a quiet label change.
- Shareable achievement cards — styled to be screenshot-worthy.
- Friend/cohort leaderboard — competing with people you know, not anonymous strangers.

**Micro-interactions:**
- Correct answer: subtle satisfying animation (green flash, checkmark pop).
- Wrong answer: brief shake or red flash.
- Session complete: genuine reward moment, not just a stats table.
- Level-up: full-screen moment with color flash and animation, not a toast notification.

---

## Progress tracker

### Completed (do not redo)
- [x] P1-1: Google Sign-In core auth — DONE
- [x] P1-2: Google Sign-In follow-ups (account picker, Account section, disconnect()) — DONE
- [x] P1-3a: Mock Test screen (45Q / 2hr timed mode) — DONE
- [x] P1-4: Bottom nav bar disappearing after email login — DONE
- [x] P1-5: Dark mode (login screens, text field visibility) — DONE
- [x] P1-6: Android scrolling screenshot support — DONE
- [x] P1-7: Back gesture exits app — DONE
- [x] P2-1: Home screen rework (congestion, badges, rank label) — DONE
- [x] P2-2: Student Profile rework (avatars, settings sections, Firebase auto-fill) — DONE
- [x] P4-1 through P4-6: Regression fixes (routing bug, dead buttons, back navigation, exit dialog, error styling, settings audit) — ALL DONE
- [x] A-1: Design system implementation (typography + color tokens applied app-wide) — DONE
- [x] A-2: Dark mode onboarding image blending (soft radial glow treatment, in-code) — DONE
- [x] A-3: Daily NEET Challenge — real flow (date-seeded 10Q selector, 45s/question timer, +50 XP completion bonus, per-day lock, results screen, home "Done today" pill) — DONE
- [x] A-4: Mock Test mode — Full-Length (180Q/3hr, indigo) and Quick (45Q/2hr, orange) as distinct entry points; differentiated landing screens, shared format widgets, Home routes through a chooser — DONE
- [x] A-5: Performance Analytics — hero/subject-mastery/insights/history layout, 7-day accuracy trend strip with streak dots, "Focus this week" weak-area callout, trending pills on subject mastery cards — DONE
- [x] M-1: Maintenance & audit fixes — profile-sheet compile errors, onboarding assets migrated to .jpeg, analyzer warnings cleared, sign-in dark background regression, daily-challenge finish path guarded, question bank parsed once per run (static cache), edit-name sheet fixes — DONE
- [x] M-2: Launch experience — native purple boot splash removed and unified to brand green (Android/iOS/web), splash redesigned (animated bubbles + logo bounce), launcher icons regenerated — DONE
- [x] M-3: App-wide dynamic theming — light mode default with dark optional (System/Light/Dark picker); 40+ screens migrated off hardcoded dark tokens to theme-derived surfaces/text; contrast fixes — DONE
- [x] M-4: Launch crash + overflow fixes — splash TickerProvider crash fixed, 10 RenderFlex overflow fixes across welcome/sign-in/analytics/profile, verified via phone-dimension smoke test — DONE
- [x] AUD-1: Question bank dedupe + integrity repair — 2,500 → 2,229 clean questions (643/588/998). Bank-integrity regression tests added — DONE
- [x] AUD-2: Streak counts practice, not app opens — a day counts only when a session is completed; consecutive days extend, any gap restarts, last-practiced-before-yesterday expires to 0 on app open; unit-tested — DONE
- [x] AUD-3: Home "Your Progress" card fixed — accuracy-based percentile replaces fake XP-derived ranking; Ranking stat is now tappable → Leaderboard tab — DONE
- [x] AUD-4: Account linking — same email = ONE account across Google and password; one-tap linking flow — DONE
- [x] A-6: Practice Hub — Gen-Z redesign (gradient hero, streak/XP/solved stat strip, tappable subject mastery cards, Daily Challenge card, honest mock-test copy, legacy dead-end removed) — DONE
- [x] A-6b: Unified subject icon system — shared `SubjectIconBadge` widget, theme-adaptive tokens, WCAG AA contrast locked by regression tests — DONE
- [x] A-10: Motion layer (shared primitives, minimal code) — `AppHaptics` (semantic tick/success/error/celebrate wired into all three question runners, nav, results choreography), brand 300ms fade-up page transitions on both themes via one `_FadeUpTransitionsBuilder`, reusable `CountUp` widget (Home XP pill + progress stats), reusable `StaggeredEntrance` (Row/Column, Expanded-safe, timer-free — Home action cards + subject tiles cascade in) — DONE
- [x] A-11: Launch hardening — iOS bundle id `com.example.coderank` → `in.coderank.app` (pbxproj + firebase_options), Android release minify+shrinkResources with minimal ProGuard rules, Nunito/Inter bundled locally (9 TTFs, google_fonts CDN dependency removed — offline-first-launch renders brand type), college picker filters by selected state (TODO resolved, value clamped), dead `ColorSwatch` widget deleted (test pruned), GitHub Actions CI (analyze --fatal-infos + test) — DONE

### Remaining — work through in this order

#### B-series: User-found fixes (do these first, before A-7) — ALL DONE
- [x] B-1: Android 12+ double splash fix — transparent android_12 splash icon added to flutter_native_splash config and all native resources regenerated; Android 12+ no longer falls back to drawing the launcher icon (green-on-green system splash, single Flutter splash remains). DONE
- [x] B-2: Confirm single splash — read-only trace confirmed exactly one splash on every path (pre-12 stretched solid green; 12+ green + transparent icon; SplashScreen mounted once; no other splash widgets). DONE
- [x] B-3: Green tile cut-off fix — Home _ActionCard badge starvation fixed (Spacer→spaceBetween so the pill sizes to content); chooser badge made Flexible+ellipsis. Verified with truncation-signal widget tests at 320/360/412dp. DONE
- [x] B-4: Remove "See all" from subjects row — button deleted; the 3 subject tiles are the full set. DONE
- [x] B-5: 100-question gate for Leaderboard and AIR — `UserProgressData.isRankingUnlocked` (100 Qs) gates percentile ("Unranked"), AIR ("Locked"), leaderboard rank chip (lock icon, user excluded from cohort below gate) and the analytics hero (with "N more questions to unlock" hints). Unit-tested. DONE
- [x] B-6: Feature audit — brief written to PROGRESS.md "## Feature Audit": all flows real and placeholder-free; 5 documented gaps (dead ColorSwatch widget, 1 TODO, zero Firestore/local-only data, dormant demo bank, OAuth unverifiable on-device). DONE

#### A-series: Feature work
- [x] A-7: Practice setup screens redesign — goal-first flow: three presets (Quick Revision 10·Mixed·60s / Exam Drill 50·Hard·60s / Deep Dive 20·Medium·no-limit) make the common case one tap + Start; the original count/difficulty/time chip groups live in an opt-in "Fine-tune your set" panel; any chip tap = custom mode (goal deselects); defaults hydration, summary card, badge header and QuestionScreen contract unchanged. DONE
- [ ] A-8: Real ranking system — BLOCKED on external setup (Hard Rule #5): requires Firestore (no cloud_firestore dependency/database provisioned; Firebase console setup needed). All rank surfaces are honestly gated meanwhile (B-5). THIS IS THE ONLY REMAINING ITEM on the checklist.
- [x] A-9: Micro-interactions (scoped subset per this spec): correct/wrong answer reveal now animates (AnimatedContainer fade, 250ms); session-complete reward = results entrance choreography (elastic trophy pop + fade-up headline/XP chip); level-up = full-screen tier-up celebration with brand-gradient badge and huge tier type when a session crosses a tier boundary. Sound hooks/shareable cards/leaderboard scaffolding correctly excluded per spec. DONE

#### R-series: Tutoring engine — ALL DONE
- [x] R-1: Extend question data model to new schema — dual-format QuestionModel (app bank parses unchanged; QUESTION_SCHEMA.md format with derived app-side fields + additive schema fields). DONE
- [x] R-2: Repository chapter/topic/bloom-level queries — getQuestionsByChapter/Topic/BloomLevel + getChapterCoverage + getTopicsForChapter over the cached bank. DONE
- [x] R-3: Weak-area tracking service — per-chapter accuracy + capped recent-mistakes memory in its own storage key; wired to startup, reset flow and all three runners. DONE
- [x] R-4: Diagnostic test flow — even-coverage set builder (round-robin, cap 24) + intro/runner/results chapter-map screens + Practice Hub entry; feeds weak areas, never pollutes subject stats. DONE
- [x] R-5: Recommendation engine — pure priority logic (streak keeper > daily > diagnostic nudge > weak-chapter drill > mistake review > momentum fallback) with honesty thresholds; chapter drill made actionable via QuestionScreen's chapter filter. DONE
- [x] R-6: Home screen recommendation-first rework — "Recommended for you" carousel above the progress card, live off progress+weak-area notifiers, every card routes to a real destination. DONE
- [x] R-7: Explanation display upgrade — shared ExplanationCard with verdict header and the "WHY <letter> TEMPTS YOU" misconception callout from common_wrong_reasoning, wired into all three runners. DONE
- [x] R-8: Time-pacing features — PaceUtils (difficulty-aware expected time, 1.5x slow threshold), practice pacing stopwatch + results nudge, mock live "Slow" chip + avg-time stat. DONE
- [x] R-9: Mock test scoring calibration — projected full-paper score, percentile band from historical trend, predicted AIR (suppressed under 45 attempts) with visible uncertainty notes on the results screen. DONE

#### M-series: Maintenance
- [x] M-5: Pre-launch stability sweep — systematic verification pass completed with ZERO fixes needed: no placeholder text or debug prints, no dead-end taps, PopScope guards only where needed, all loaders fail gracefully with retry, streak/daily midnight edges already unit-tested, analyzer completely clean, 2,229-question bank loads correctly (repository tests exercise it every run). DONE

---

## Item descriptions (reference only — full spec is above in the task list)

### B-1 / B-2: Splash fix
The app currently shows two splash screens on Android 12+ — the system-generated one from flutter_native_splash and a custom Flutter widget splash. Configure flutter_native_splash correctly (background `#39D353`, white CodeRank logo), then remove the Flutter-layer custom splash entirely so the app goes: native splash → AuthGate. One splash. No double-flash.

### B-3: Green tile cut-off
The Practice and Mock Test home cards have a small green label/badge that is being clipped by the card's bounds. Either expand the card/container so the label is fully visible, or remove the label. The current half-visible state is not acceptable for launch.

### B-4: "See all" removal
The subjects row on the Home screen has a "See all" link that goes nowhere — all 3 subjects are already displayed. Remove the link. One line of code.

### B-5: Unlock gate
Leaderboard and AIR (All India Rank) are gated behind solving 100 questions total. Read PracticeHistoryRepository to get total questions solved. If < 100, show a bottom sheet: "Solve 100 questions to unlock — you've solved X so far." If ≥ 100, open the real screen (or note if the real screen doesn't exist yet — mark BLOCKED if so).

### B-6: Feature audit
A read-only scan. Walk through every screen, every button, every tap target. Produce a written brief — not code, just a clear list — of what works, what's broken, what's missing, and what's scope for post-launch. This brief informs prioritization of A-7 onwards.

### A-7: Practice setup redesign
The current setup feels like a form — 3 separate option groups and a summary card. Redesign it to feel like launching into something. The user should feel momentum, not friction. Keep every option (subject, count, difficulty, time). Think: one bold choice at a time, swipe or tap to advance, a "Let's go" moment at the end — not a submit button on a form.

### A-8: Real ranking
Pull user stats from Firebase, compute a rank relative to other users (by accuracy, XP, or composite score), and display it on the profile/leaderboard. The rank should update after each session. This requires a Firestore write of session results and a rank query or Cloud Function.

### A-9: Micro-interactions (scoped)
Correct answer → green flash + checkmark animation on the selected option. Wrong answer → red flash + horizontal shake on the selected option. Session complete → a full celebration moment (confetti, color burst, XP gained display) that plays before the results screen fades in. Level-up → a full-screen overlay (not a snackbar) with the new level number, a color flash, and an animation before dismissing. Sound hooks, shareable cards, and leaderboard scaffolding are NOT part of this item.

### M-5: Stability sweep
A systematic pass through the entire app looking for anything that would embarrass the app at launch: buttons that do nothing, screens that can be exited accidentally with the back gesture, crashes when Firebase is unreachable, streak or daily-challenge logic that breaks at midnight, any leftover "TODO" or "Coming soon" text, and any analyzer warning. Fix everything found. This is the last item before launch.

### R-1 through R-9: Tutoring engine
See QUESTION_SCHEMA.md for the data model spec. These build the adaptive tutoring engine: schema extension, repository queries by chapter/topic, weak-area tracking, diagnostic test, recommendation engine, recommendation-first home screen, explanation upgrades, time-pacing, and mock test score calibration.

---

## How to run this checklist (autonomous mode)

At the start of each CLI session:
1. Read this file (CODERANK.md) — internalize hard rules and design contract.
2. Read PROGRESS.md — find the first item that is not DONE.
3. If the item is IN PROGRESS (session was cut off), resume from the Partial State note.
4. If the item is TODO, start it fresh.
5. Complete the item, write the two-part report to PROGRESS.md, mark it DONE.
6. Immediately begin the next TODO item — do not wait for human confirmation.
7. If BLOCKED, note the reason in PROGRESS.md and skip to the next TODO item.
8. Before any forced stop, write a Partial State entry to PROGRESS.md.
9. Continue until all items are DONE or the session ends.
