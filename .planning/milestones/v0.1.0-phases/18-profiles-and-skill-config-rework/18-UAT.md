---
status: complete
phase: 18-profiles-and-skill-config-rework
source: [18-01-SUMMARY.md, 18-02-SUMMARY.md, 18-03-SUMMARY.md]
started: 2026-03-21T23:30:00Z
updated: 2026-03-22T00:00:00Z
---

## Current Test

[testing complete]

## Tests

### 1. All skills default unchecked
expected: Open config, select any mob. All skills unchecked, compact rows.
result: pass

### 2. Checking a skill expands config options
expected: Check a skill. Config options expand below.
result: pass

### 3. Unchecking a skill collapses config
expected: Uncheck a skill. Config options collapse, preview clears.
result: pass

### 4. Timed toggle with timer fields
expected: Timed toggle enables/disables number inputs. Numbers only, max 1200.
result: pass

### 5. Sound Alert checkbox gates sound controls
expected: Sound Alert unchecked grays controls, checked enables them.
result: pass

### 6. Show preview (static)
expected: Untimed skill Show creates static icon with label. Hide removes.
result: pass

### 7. Show preview (timed with sweep)
expected: Timed skill Show creates icon with cooldown sweep.
result: pass

### 8. Preview clears on config close
expected: Close config clears all previews.
result: pass

### 9. Reset clears skill config and preview
expected: Reset clears config and preview.
result: pass

### 10. Profile selector dropdown
expected: Dropdown shows profiles, select closes it.
result: pass

### 11. Create new profile
expected: New creates blank profile, auto-selects.
result: pass

### 12. Delete profile
expected: Del with confirmation, switches to Default.
result: issue
reported: "Deleting works but should clear the profile selecting popup, otherwise a deleted profile can still be picked"
severity: minor

### 13. Profile export
expected: Exp shows encoded string popup.
result: pass

### 14. Profile import
expected: Imp paste popup creates new profile.
result: pass

### 15. No Lua errors on load
expected: /reload no errors.
result: pass

## Summary

total: 15
passed: 14
issues: 1
pending: 0
skipped: 0

## Gaps

- truth: "Delete profile closes the profile selector popup"
  status: failed
  reason: "User reported: deleting works but should clear the profile selecting popup, otherwise a deleted profile can still be picked"
  severity: minor
  test: 12
  artifacts: []
  missing: []
  debug_session: ""
