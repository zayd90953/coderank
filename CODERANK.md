# CodeRank — Master Checklist

**Project:** CodeRank — Flutter/Dart Android NEET exam prep app  
**Foundation:** Existing codebase (Firebase/Google Sign-In working, navigation shell, question repository, 2,500 questions, existing assets)  
**Goal:** A complete adaptive NEET tutoring app — not an MVP, a genuinely good v1 — built on top of the existing foundation, one item at a time.  
**Current date:** September 2026

---

## Hard rules — Claude Code must never violate these

1. **One item at a time.** Do only the single item you're on. Do not start the next, even if it seems fast or related.
2. **No fake completions.** No placeholders, stubs, or easier substitutes reported as done. If incomplete, mark `PARTIAL` or `BLOCKED` with exactly what's missing.
3. **Trace before claiming done.** Only mark `DONE` after confirming the actual behavior, not just that a file was touched.
4. **Audit before redesigning.** Before any UI rework item, list what you're about to change and why. Do not redesign beyond the scope of the item — scope creep is what caused the P2-1/P2-2 regression.
5. **External setup stops you.** If something needs Firebase console, API keys, or credentials outside the codebase, stop and ask.
6. **Every item ends with a two-part report:**
   - Plain-English summary (2-4 sentences, no code terms, no file names) — what changed, what it means for how the app behaves.
   - Status line: `DONE` / `PARTIAL` / `BLOCKED` with one line on what's missing if not DONE.
7. **Stop and wait** after every report. Do not proceed until told to continue.
8. **Windows PowerShell environment.** Do not use Unix-only shell commands (sed, grep, awk). Use PowerShell-native equivalents or make file edits directly through file-editing tools.

---

## Design contract — reference this on every UI item

Claude Code must read and follow this before touching any screen. This is the visual identity of CodeRank — nothing should be built that contradicts it.

**Philosophy:** Light-first, dark-ready, bold, and game-like. The app competes for attention with social media and games — it needs to feel like it belongs there, not like a textbook. The default experience is light mode, while dark mode is a fully supported, adaptive alternative.

**Color system:**
- Background: use the active theme’s surface token; light mode is the default and dark mode uses the near-black canvas.
- Surface cards: use the active theme’s surface/container token; cards must adapt cleanly instead of using fixed light or dark colors.
- Text: use the active theme’s `onSurface` for primary text and `onSurfaceVariant` for secondary text.
- Error/destructive: use the active theme’s `error` token.
- Brand accent: Electric Green `#39D353` is the only primary brand color. Gold, orange, and red may appear only as tiny domain or achievement accents.

**Typography:**

**Typography:**
- Display/headlines/scores: a rounded, personality-forward font (e.g. Nunito or Space Grotesk) — never the Flutter default
- Body/question text: a clean, highly legible font optimized for reading under time pressure (e.g. Inter or DM Sans)
- Two fonts maximum. Consistent hierarchy throughout.

**Game-like mechanics (must be present, not optional):**
- Streak counter with real visual weight — not a small badge, a satisfying animated moment when it grows
- XP/level system with a genuine level-up event (animation, color flash) — not a quiet label change
- Shareable achievement cards — "Top 5% this week" styled to be screenshot-worthy
- Friend/cohort leaderboard — competing with people you know, not anonymous strangers

**Micro-interactions:**
- Correct answer: subtle satisfying animation + sound (optional but recommended)
- Session complete: genuine reward moment, not just a stats table
- Level-up: full-screen moment, not a toast notification

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
- [x] A-4: Mock Test mode — keep both Full-Length (180Q/3hr) and Quick (45Q/2hr) as distinct entry points; differentiated landing screens (indigo vs orange hero), shared format widgets, Home routes through a chooser — DONE
- [x] A-5: Performance Analytics — kept the existing hero/subject-mastery/insights/history layout and added three new sections: 7-day accuracy trend strip with streak dots, "Focus this week" weak-area callout (subject-level), and trending pills on each subject mastery card — DONE
- [x] M-1: Maintenance & audit fixes — profile-sheet compile errors fixed, onboarding assets migrated to .jpeg with all references verified, analyzer warnings cleared, sign-in dark background regression restored, daily-challenge finish path guarded, question bank parsed once per run (static cache), edit-name sheet keyboard/controller/example-hint fixes — DONE
- [x] M-2: Launch experience — native purple boot splash removed and unified to brand green (Android/iOS/web), splash redesigned (animated bubbles + logo bounce), launcher icons regenerated from new app icon — DONE
- [x] M-3: App-wide dynamic theming — light mode is the default with dark optional (System/Light/Dark picker); 40+ screens migrated off hardcoded dark tokens to theme-derived surfaces/text; contrast fixes for settings tiles and mock-test landing heroes — DONE
- [x] M-4: Launch crash + overflow fixes — splash TickerProvider crash fixed (red screen on device), 10 RenderFlex overflow fixes across welcome/sign-in/analytics/profile, verified via phone-dimension smoke test across 12 screens — DONE

### Remaining — work through in this order
- [ ] A-6: Practice Hub — Gen-Z redesign
- [ ] A-7: Practice setup screens — redesign (not just restyle)
- [ ] A-8: Real ranking system (computed from actual user data, not hardcoded)
- [ ] A-9: App-wide production polish pass
- [ ] AUD-1: Deduplicate the question bank (113 duplicate question texts) — needs a dedupe policy decision
- [ ] AUD-2: Streak/XP bonus is granted on app open, not on practice — needs a definition of "streak"
- [ ] R-1: Extend question data model to new schema (see QUESTION_SCHEMA.md)
- [ ] R-2: Update question repository for chapter/topic/bloom-level queries
- [ ] R-3: Weak-area tracking service
- [ ] R-4: Diagnostic test flow (new feature)
- [ ] R-5: Recommendation engine (what to study next)
- [ ] R-6: Home screen — recommendation-first rework (builds on A-5 redesign)
- [ ] R-7: Explanation display upgrade (common wrong reasoning)
- [ ] R-8: Time-pacing features in practice/mock sessions
- [ ] R-9: Mock test scoring calibration (predicted score/percentile)

**Note on A-4 (Full NEET Paper vs Mock Test):** Resolved — kept both. Full-Length (180Q/3hr, indigo) is the real-deal NEET exam, Quick (45Q/2hr, orange) is the warm-up. Home routes to a chooser between the two. See A-4 entry in Completed.

---

## Item descriptions

### A-1: Design system implementation
Read the Design Contract above carefully. Create a `lib/core/design/` folder with:
- `app_colors.dart` — all color tokens as named constants (background, surface, primary, secondary accent, text primary, text secondary)
- `app_typography.dart` — the two-font system with named text styles (display, headline, body, caption)
- `app_theme.dart` — a full `ThemeData` (dark as default) built from these tokens

Then do a sweep of every screen and replace any hardcoded color or font reference with the design token equivalents. Do NOT redesign layouts in this item — this is token-replacement only. Confirm `flutter analyze` is clean and the app still builds before marking done.

### A-2: Dark mode onboarding image blending
The onboarding images are flat assets that don't blend with the dark background in dark mode — they look pasted on. Add dark-mode-appropriate image variants OR a container/blend treatment so they integrate naturally with the dark background. Do not redesign the onboarding flow itself.

### A-3: Daily NEET Challenge — real screen
Replace the current "Coming soon" placeholder. Daily Challenge should have its own dedicated flow: a curated set of 5-10 high-yield questions (pulled from the existing question bank, varied subjects), presented with a daily timer/deadline feel, rewarding +50 XP on completion. This is distinct from regular practice and from the mock test.

### A-4: Full NEET Paper mode — confirm and implement
Confirm with the user whether Full NEET Paper (180Q/3hr) should stay as a separate mode from Mock Test (45Q/2hr) or be collapsed into one. Wait for confirmation before implementing. If kept separate, ensure it's genuinely distinct in setup, UI, and results — not just the same mock test screen with a different question count.

### A-5: Performance Analytics — Gen-Z redesign
Currently plain and functional — needs a redesign that balances Gen-Z visual energy with clean readability. Reference the Design Contract. This screen becomes the visual reference point for the whole app — get it right here before touching A-6/A-7. Subject mastery bars, accuracy trends, streak history, and weak-area summary should all be present. Avoid generic chart library defaults — make this feel like a reward screen, not a spreadsheet.

### A-6: Practice Hub — Gen-Z redesign
Same design direction as A-5. Apply to the Practice tab. Keep all existing functionality — this is a visual and interaction upgrade, not a feature change.

### A-7: Practice setup screens redesign
The current 3-option-groups + 1-summary-card pattern across Physics/Chemistry/Biology setup should be fundamentally reconsidered, not just restyled. The goal is a setup flow that feels fast and purposeful, not like filling out a form.

### A-8: Real ranking system
Replace the static/hardcoded "Unranked" placeholder with a genuine ranking computed from real user data stored in Firebase — accuracy, questions solved, XP — across the actual user base. Leaderboard should show both global rank and friend/cohort rank once friend system exists (friend system is a future item — for now, global ranking only).

### A-9: Production polish pass
Once A-1 through A-8 and R-1 through R-8 are stable: micro-interactions (correct answer feedback, session complete moment, level-up event), sound design hooks (optional, just structure), shareable achievement cards, and a final pass for consistency and completeness across every screen.

### R-1 through R-9: Tutoring engine
See QUESTION_SCHEMA.md for the data model spec. R-1 through R-9 build the adaptive tutoring engine: schema extension, repository queries by chapter/topic, weak-area tracking, diagnostic test, recommendation engine, recommendation-first home screen, explanation upgrades, time-pacing, and mock test score calibration. These depend on the question bank being re-tagged — R-1 and R-2 can be built against the existing (partially-tagged) bank, with full functionality coming as tagging progresses.

---

## How to run this file

Name one item (e.g. "do A-1 from CODERANK.md"), get the two-part report, test/verify, then move to the next. Never batch multiple items. The design contract section must be read before any UI item — reference it explicitly in the instruction, e.g. "do A-5 from CODERANK.md, reading the Design Contract section first."
