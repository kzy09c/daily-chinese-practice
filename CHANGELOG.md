# Changelog

## 2026-10-17: random selection and skipping

- Added a Skip / Next word button, plus Enter and right-arrow shortcuts.
- Replaced the fixed daily sequence with random selection, allowing later repeats.
- Saved the current word across restarts in state.json, with atomic writes.
- Added tests for skipping, persistence, date changes, repeats, and invalid state.
- Retuned the 1,000-entry vocabulary towards harder words and practical expressions.
- Restored the original unreviewed vocabulary, replacing only 41 clearly basic entries.
- Updated the screenshot and documentation.

## 2026-10-17: vocabulary expansion

- Expanded the vocabulary to 1,000 distinct entries.
- Added vocabulary for discussion, relationships, work, news, and technology.
