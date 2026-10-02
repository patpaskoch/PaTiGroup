# AGENTS.md — PaTiGroup

**Read the suite rules first: [`../../PaTiAdmin/AGENTS.md`](../../PaTiAdmin/AGENTS.md).** They apply here in full.
Addon facts: `../../PaTiAdmin/docs/ARCHITECTURE.md` · open issues: `../../PaTiAdmin/docs/FOLLOW_UPS.md`.

## This addon
- Purpose: **party awareness** — who tanks, who heals, role counts, the tank's target and its raid marker. Display
  only. Never: set markers, ready check, pull timer, leader actions (that is PaTiLead), threat/aggro (PaTiTank),
  HoTs/heal details (PaTiHeal), rotation, targeting, follow, anything automatic.
- Since 2026-10-02 a new addon under the old name: the former PaTiGroup is PaTiLead. Its `PaTiGroupDB` (schema 1)
  is never read; its test IDs `PT-GROUP-001…199` are retired — new tests start at `PT-GROUP-200`.
- Files: `Logic.lua` (settings, migration, member/summary normalization, target tokens — pure, tested) ·
  `PaTiGroup.lua` (API adapter `readMembers`, window, settings, commands, events) · `Locales/` · `Shared/` (synced,
  never edit).
- SavedVariables: `PaTiGroupDB` (per character), schema 2 — see `Logic.DEFAULTS`.
- Secure / combat-sensitive: none (plain frames; updates in combat are fine).
- Slash: `/pg`, `/ptg`, `/patigroup`.

## Checks
`bash ../../PaTiAdmin/tools/check.sh .` before every commit. Manual WoW tests: `INGAME_TESTING.md`.
