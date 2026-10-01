# CodeRank — NEET Prep App Enhancement Checklist

## 🎯 **Immediate Quick Wins (This Week)**

### 1. **PYQ (Previous Year Questions) Practice Mode** ⭐⭐⭐
- [ ] Add PYQ filter to Practice Setup Screen
- [ ] Add "Practice PYQs" option in Practice Hub
- [ ] Filter questions where `neetPyqYear != null && neetPyqYear.isNotEmpty`
- [ ] Show PYQ badge on question cards

### 2. **"Review Mistakes" Feature** ⭐⭐⭐
- [ ] Add "Review Mistakes" button to Results Screen
- [ ] Pull from `WeakAreaTrackingService.recentMistakeIds()`
- [ ] Create dedicated review session with those questions
- [ ] Show misconception callouts (already supported via `commonWrongReasoning`)

### 3. **Topic-Level Practice Entry** ⭐⭐
- [ ] Add topic selector to Practice Setup (when schema data exists)
- [ ] Use `QuestionRepository.getQuestionsByTopic()`
- [ ] Show topic list per chapter

### 4. **Export Analytics as PDF** ⭐⭐
- [ ] Add "Export Report" button to Analytics Screen
- [ ] Generate PDF with: overall stats, subject mastery, weak chapters, trend chart

### 5. **Weak Chapter Drill from Home** ✅ **ALREADY IMPLEMENTED**
- Home recommendations → `_openChapterDrill` → `QuestionScreen(chapter: ...)`

---

## 🔥 **High Impact (Next 2-4 Weeks)**

### 6. **Schema Tagging of Full Question Bank** ⭐⭐⭐⭐⭐ (DATA WORK)
- [ ] Tag all 2,200+ questions with: `topic`, `bloom_level`, `common_wrong_reasoning`, `neet_pyq_year`, `avg_time_seconds`, `ncert_class`
- [ ] This unlocks: topic practice, bloom-level practice, adaptive review, PYQ filtering, misconception callouts
- [ ] Priority: Biology (1000 Qs) → Physics (750 Qs) → Chemistry (750 Qs)

### 7. **Adaptive Weak-Area Practice (Spaced Repetition)** ⭐⭐⭐⭐
- [ ] Build `AdaptivePracticeEngine` using `WeakAreaTrackingService`
- [ ] Prioritize: low-accuracy chapters + recent mistakes + spaced intervals
- [ ] Replace "Daily 10 Random" with "Daily 10 Smart"

### 8. **Syllabus Progress Tracker** ⭐⭐⭐
- [ ] NCERT chapter → % attempted, accuracy, mastery level
- [ ] Visual progress bars per chapter
- [ ] "Syllabus Completion" % on home/profile

### 9. **Offline-First Architecture** ⭐⭐⭐
- [ ] Cache question bank locally (already in assets)
- [ ] Queue Firestore writes when offline
- [ ] Practice works 100% offline; sync on reconnect

### 10. **Bilingual Support (Hindi + English)** ⭐⭐⭐
- [ ] Add Hindi translations for UI strings
- [ ] Add Hindi explanations to questions
- [ ] Language toggle in settings

---

## 🚀 **Strategic Differentiators (Month 2+)**

### 11. **AI Doubt Resolution** ⭐⭐⭐⭐
- [ ] "Ask AI" button on explanation cards
- [ ] Context-aware: sends question + user's wrong answer + explanation
- [ ] Fallback to community/tutor escalation

### 12. **Study Planner / Daily Schedule** ⭐⭐⭐
- [ ] Target exam date → backward-planned daily targets
- [ ] "Today: Physics - Kinematics (20 Qs), Chemistry - Ionic Eq (15 Qs)"
- [ ] Adjusts based on weak areas

### 13. **Video Explanation Links** ⭐⭐⭐
- [ ] Add `videoUrl` field to schema
- [ ] Embed YouTube/Drive links for key concepts
- [ ] "Watch 2-min explanation" button

### 14. **Peer Compare / Study Groups** ⭐⭐
- [ ] Anonymous percentile within same syllabus progress
- [ ] "Students at your level average 72% in Physics"

### 15. **Teacher/Parent Dashboard** ⭐⭐
- [ ] Shareable progress link (read-only)
- [ ] Weekly email summary

---

## 📊 **Current Data Reality Check**

| Asset | Status | Count |
|-------|--------|-------|
| Total Questions | In assets | ~2,229 |
| Schema-format (fully tagged) | **Only demo** | ~3 |
| App-format (basic fields only) | **Needs tagging** | ~2,226 |
| Questions with `explanation` | All | ✅ |
| Questions with `neetPyqYear` | Schema only | ~3 |
| Questions with `commonWrongReasoning` | Schema only | ~3 |
| Questions with `topic`/`bloom_level` | Schema only | ~3 |

**The schema/model/code is READY — only DATA tagging is missing.**

---

## 🏗️ **Architecture Notes**

- **No new dependencies needed** — everything uses existing services
- **Schema format already supported** in `QuestionModel.fromJson()`
- **Repository queries exist** for chapter/topic/bloom/PYQ
- **ExplanationCard** already renders misconception callouts
- **RecommendationEngine** already suggests weak chapter drills
- **WeakAreaTracking** already feeds the engine

---

## 🎯 **Recommended Implementation Order**

| Week | Focus | Deliverable |
|------|-------|-------------|
| 1 | Quick Wins 1-4 | PYQ mode, Review Mistakes, Topic entry, PDF export |
| 2-3 | Data Tagging | Tag 500 high-yield questions (start with PYQs) |
| 4 | Adaptive Engine | Smart daily practice replacing random daily |
| 5-6 | Syllabus Tracker | Chapter-level progress UI |
| 7-8 | Offline + Hindi | Core accessibility features |

---

## ✅ **Definition of Done for Each Item**

- [ ] Code compiles (`flutter analyze` clean)
- [ ] Works on Android emulator
- [ ] No regression in existing flows
- [ ] APK builds successfully (`flutter build apk --release`)

---

*Last updated: 2026-09-30*
*Generated from codebase analysis*