# AGENTS.md — PaTiGroup

**Read the suite rules first: [`../../PaTiAdmin/AGENTS.md`](../../PaTiAdmin/AGENTS.md).** They apply here in full.
Addon facts: `../../PaTiAdmin/docs/ARCHITECTURE.md` · open issues: `../../PaTiAdmin/docs/FOLLOW_UPS.md`.

## This addon
- Purpose: **party awareness** — who tanks, who heals (one line), the tank's target with its portrait and raid marker. Display
  only, except one click on the tank target (owner 2026-10-14). Never: set markers, ready check, pull timer, leader actions (that is PaTiLead), threat/aggro (PaTiAggro),
  HoTs/heal details (PaTiHeal), rotation, follow, any targeting by itself, anything automatic.
- Since 2026-10-02 a new addon under the old name: the former PaTiGroup is PaTiLead. Its `PaTiGroupDB` (schema 1)
  is never read; its test IDs `PT-GROUP-001…199` are retired — new tests start at `PT-GROUP-200`.
- Files: `Logic.lua` (settings, migration, member/summary normalization, target tokens — pure, tested) ·
  `PaTiGroup.lua` (API adapter `readMembers`, window, settings, commands, events) · `Locales/` · `Shared/` (synced,
  never edit).
- SavedVariables: `PaTiGroupDB` (per character), schema 2 — see `Logic.DEFAULTS`.
- Secure / combat-sensitive: one SecureActionButton `PaTiGroupTankTargetButton` (owner 2026-10-14: click the tank
  target), type1 "target", unit "<tank>target"; parented to UIParent and laid over the target line in screen
  coordinates (not a window child). Attributes, position and visibility only out of combat (pending until
  PLAYER_REGEN_ENABLED). In combat: no move, collapse or hide (COMBAT_LOCKED; PaTiSuite gets false). Never targets
  by itself; hidden when you are the tank.
  Two more (owner 2026-10-18): `PaTiGroupTankButton` and `PaTiGroupHealerButton` over the halves of the tank/healer
  line, type1 "target", unit = that member; same rules (out of combat only, hidden when nobody has the role).
- Slash: `/pg`, `/ptg`, `/patigroup`.

## Checks
`bash ../../PaTiAdmin/tools/check.sh .` before every commit. Manual WoW tests: `INGAME_TESTING.md`.
