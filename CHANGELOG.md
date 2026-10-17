# Changelog

Format: `## [Unreleased]` / `## [x.y.z] - YYYY-MM-DD` with Added, Changed, Fixed, Removed, Known Issues.

## [Unreleased] — 0.1.0
### Changed
- Tank and healer share one line, the tank target shows the enemy's portrait in front (owner 2026-10-17: a face reads as
  something you can click). The window is two lines shorter. Tank and healer each show "dead" / "offline" (before only
  the healer did; owner 2026-10-17: "the tank's death is not shown").
- The tank target stands out (owner 2026-10-14: "would have liked to see it better"): it is now the first line, taller,
  on its own lighter panel with an accent stripe, with a larger name and raid marker.
### Added
- Click the tank-target line to target that enemy (owner 2026-10-14) — like /assist, also in combat (the click takes
  what the tank has targeted right then). One secure button, set up out of combat; for a key binding use a macro
  `/click PaTiGroupTankTargetButton`. In combat the window can no longer be moved, collapsed or hidden.
- Themes (owner wish 2026-10-03): Settings → Window → Theme — Default (the PaTi look as before), WoForever (warm brown, gold/bronze) or Dracula (dark, purple/pink/cyan accents). Colours only; layout, secure buttons and behaviour are unchanged. Saved per character in this addon (`theme`, unknown values → Default); Restore Defaults returns to Default. PaTiSuite can switch all PaTi windows at once.
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
### Changed
- The window can also be moved in combat (it has no secure buttons; PaTiShared `SetCombatMovable`, hardening 2026-10-02). A broken saved position falls back to the default instead of breaking the login.
### Fixed
- Hardening: a broken SavedVariables save (not a table, a broken schema or scale) no longer breaks the login; only the broken value is replaced, every valid setting (also `false`) stays, and the migration is idempotent (tests/robustness_spec.lua).
### Removed
- The Roles line ("1 Tank · 1 Heal · 3 DD", owner 2026-10-17: not needed).
### Known Issues
- Not tested in game yet (`INGAME_TESTING.md`). Whether roles are reported outside the group finder is unconfirmed.
