# PaTiGroup

<img src="assets/icon-128.png" width="96" alt="PaTiGroup icon">

Party awareness for World of Warcraft: Forever (Interface 16001): see at a glance who tanks, who heals, and what
the tank has targeted — with its raid marker. Display only: PaTiGroup never targets, marks or casts anything.

> Status: in development, not yet released. Not yet tested in game.
>
> This is a **new** PaTiGroup (2026-10-02). The former PaTiGroup (raid markers, ready check, pull timer) is now
> [PaTiLead](https://github.com/patpaskoch/PaTiLead). Old PaTiGroup settings are not taken over.

```
┌ PaTiGroup                         ••• ┐
│ Tank      Patrick                     │
│ Heiler    Stefanie                    │
│ Tankziel  ☠ Dunkler Kultist           │
│ Rollen    1 Tank · 1 Heal · 3 DD      │
└───────────────────────────────────────┘
```

## Features
- **Tank:** the tank's name (you first, if you tank yourself; "+1" when there are more tanks)
- **Healer:** the healer's name, with "dead" or "offline" when WoW reports it
- **Tank target:** what the tank has targeted, with its raid marker; "no target" when there is none
- **Roles:** "1 Tank · 1 Heal · 3 DD", plus members without a role
- Party and raid; solo: "Not in a group"
- Roles come from WoW (role check / group finder). Without assigned roles PaTiGroup shows "without role" — it never
  guesses a role from the class. Unreadable (restricted) values are never guessed either.
- No secure frames: updates normally in combat.
- ••• menu: Settings, Lock, Collapse, Test Mode, Hide. Settings: language, scale, lock, panel opacity.
  Languages: English, Deutsch (others fall back to English)

Not part of PaTiGroup: raid markers, ready check, pull timer and other leader actions (→ PaTiLead), threat and aggro
(→ PaTiTank), HoTs and heal details (→ PaTiHeal).

## PaTiSuite

This addon is part of the **PaTiSuite** — a collection of small addons for World of Warcraft: Forever.
Each one is installed on its own and works on its own; none of them is needed by another.

- [PaTiSuite](https://github.com/patpaskoch/PaTiSuite) – optional control panel to show and hide the PaTi windows
- [PaTiHeal](https://github.com/patpaskoch/PaTiHeal) – healing: party frames, heal target, click casting, HoTs, dispels
- [PaTiAuras](https://github.com/patpaskoch/PaTiAuras) – buffs, procs, tracking, group buffs and weapon imbues
- [PaTiTank](https://github.com/patpaskoch/PaTiTank) – tank HUD and aggro monitor
- [PaTiRota](https://github.com/patpaskoch/PaTiRota) – your own skill priority with cooldowns and fixed cast buttons
- **PaTiGroup** – party awareness: tank, healer, roles and the tank's target *(this addon)*
- [PaTiLead](https://github.com/patpaskoch/PaTiLead) – lead the group: raid markers, ready check and pull timer
- [PaTiQuest](https://github.com/patpaskoch/PaTiQuest) – selected quest and its objectives
- [PaTiDungeon](https://github.com/patpaskoch/PaTiDungeon) – instance, group and combat status
- [PaTiSocial](https://github.com/patpaskoch/PaTiSocial) – "Party Social": quick emote and message buttons
- [PaTiAlerts](https://github.com/patpaskoch/PaTiAlerts) – one window for open problems

### Goes well with (optional)

- [PaTiLead](https://github.com/patpaskoch/PaTiLead) – the leader sets the markers PaTiGroup shows
- [PaTiSuite](https://github.com/patpaskoch/PaTiSuite) – shows and hides this window together with the other PaTi windows

## Installation
1. Download the release zip (`PaTiGroup-<version>.zip`).
2. Unpack it and copy the folder `PaTiGroup` into `World of Warcraft/<client>/Interface/AddOns/`
   (replace an old `PaTiGroup` folder completely).
3. Start WoW and enable PaTiGroup in the AddOns list.

## Commands
`/pg`, `/ptg` or `/patigroup` — alone or `toggle`: show/hide · `settings` · `test` · `show` · `hide` · `lock` ·
`unlock` · `reset` (position) · `debug` · `version`

## Known limitations
- Not tested in game yet. Whether the Forever client reports roles without the group finder is unconfirmed
  (`/pg debug` lists every member's role).
- The tank's target of another player is read from `party1target` etc.; out of range it may show "no target".

## Development

Architecture, tests and engineering rules of the suite: [PaTiAdmin](https://github.com/patpaskoch/PaTiAdmin). PaTiAdmin is not a WoW addon — players do not install it. The shared UI code (PaTiShared) is already embedded in this addon's `Shared/` folder; there is nothing extra to install.

## License
MIT — see [LICENSE](LICENSE). Copyright (c) 2026 Patrick Koch.
