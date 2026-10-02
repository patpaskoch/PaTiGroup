# Changelog

Format: `## [Unreleased]` / `## [x.y.z] - YYYY-MM-DD` with Added, Changed, Fixed, Removed, Known Issues.

## [Unreleased] — 0.1.0
### Added
- New addon PaTiGroup "party awareness" (owner decision 2026-10-02; the former PaTiGroup is now PaTiLead): one small
  window with Tank (name, "+n" for more tanks; you first if you tank), Healer (name, dead/offline), Tank target (the
  tank's target with its raid marker, or "no target") and Roles ("1 Tank · 1 Heal · 3 DD", members without a role).
  Party and raid; solo: "Not in a group". Display only: no secure frames, nothing targeted, marked or cast.
- Roles only from `UnitGroupRolesAssigned`, never guessed from the class; names, flags, roles and markers are checked
  for restricted (secret) values first — unreadable values show as unknown, secret names go straight to the text.
- Events instead of polling: roster, roles, targets (`UNIT_TARGET` only for the tank), raid markers; health,
  connection and name events only for the tank and healers.
- `PaTiGroupDB`, schema 2 (schema 1 was the former PaTiGroup's table: it is not read, the addon starts fresh).
- Settings (language, scale, lock, panel opacity), Collapse, Test Mode, `/pg`, `/ptg`, `/patigroup` with show, hide,
  toggle, test, lock, unlock, reset, settings, debug, version. English texts, German translation. MIT license.
- Icon: the PaTiSuite group icon (moved here from the former PaTiGroup, now PaTiLead).
### Known Issues
- Not tested in game yet (`INGAME_TESTING.md`). Whether roles are reported outside the group finder is unconfirmed.
