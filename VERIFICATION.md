# CodeRank — On-Device Verification Checklist

Use this checklist to verify each completed P1 fix works correctly on a real Android device or emulator.

---

## P1-2: Google Sign-In

- [ ] Open the app, tap **Sign In**
- [ ] Tap **Continue with Google** — the Google account picker should appear (not silently reuse the last account)
- [ ] Select a Google account and sign in successfully
- [ ] Verify your name and avatar appear in the profile section
- [ ] Tap **Sign Out**, then **Sign In** again — the picker should appear again, not auto-select the last account

---

## P1-3: Mock Test / Full NEET Paper / Daily Challenge

- [ ] From the Home screen, tap the **Mock Test** card (45 Qs, 2 hrs)
  - [ ] Verify it opens the Quick Mock Test setup screen (not "Coming Soon")
  - [ ] Tap **Start** — questions load and the timer starts
  - [ ] Answer a question and verify the answer is recorded
  - [ ] Navigate back — return to the Quick Mock Test setup screen
- [ ] From the Home screen, tap the **Full NEET Paper** card (180 Qs, 3 hrs)
  - [ ] Verify it opens the full-length paper setup screen
  - [ ] Verify the question count shows 180 (not 45)
- [ ] From the Home screen, tap the **Daily NEET Challenge** banner
  - [ ] Verify it opens the Daily Challenge screen (not a Biology practice flow)

---

## P1-4: Bottom Navigation Bar

- [ ] Open the app and verify the bottom nav bar (Home / Practice / Rank / Analytics) is visible immediately
- [ ] Tap each tab — all four destinations should remain visible in the nav bar
- [ ] Navigate to any inner screen (e.g., Practice Setup), then tap the nav bar's Home icon
- [ ] Verify the nav bar is still visible (no restart required)
- [ ] Restart the app — the nav bar should appear on launch without a restart after the first launch

---

## P1-5: Dark Mode

- [ ] Enable system dark mode on your device (or use Developer Options → Dark Theme)
- [ ] Open the Sign In screen — the background should be dark (not white)
- [ ] Enter text in the email field — text should be visible (white text, dark background, not white-on-white)
- [ ] Enter text in the password field — same visibility check
- [ ] Tap **Continue with Google** — button text should be visible
- [ ] Open the Home screen — verify the progress card, action cards, and subject cards all use dark-appropriate styling

---

## P1-6: Android Long-Screenshot Support

- [ ] Open any scrollable screen (e.g., Practice → select a subject)
- [ ] Use Android's native screenshot gesture → "Capture more" (scrollable long screenshot)
- [ ] Verify the long screenshot captures the full scrollable content without errors

---

## P1-7: Back Gesture Navigation

- [ ] Navigate to any inner screen (e.g., Practice Setup → Start Practice)
- [ ] Swipe back (or tap the back button) — verify you return to the previous screen, not exit the app
- [ ] On the Practice Question screen, tap the back button — verify it returns to Practice Setup, not exits
- [ ] Navigate: Home → Practice tab → Practice Setup → Question screen → back → back → verify you land back on Home (not exit)

---

## Account Linking (Firebase)

- [ ] Sign up with an email/password account (e.g., `student@test.com`)
- [ ] Sign out completely
- [ ] Tap **Continue with Google** and select the same email address (`student@test.com`)
- [ ] Verify a dialog appears: "An account already exists for student@test.com. Enter your password to link your Google account."
- [ ] Enter the correct password and tap **Link & Sign In**
- [ ] Verify you are signed in successfully and can access the app
- [ ] Sign out, then sign in again with Google — verify no linking dialog appears (account is already linked)
