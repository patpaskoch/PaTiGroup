# Ingame Testing – PaTiGroup

World of Warcraft: Forever
Interface: 16001

Diese Datei dokumentiert ausschließlich Tests im echten WoW-Client.

Automatisierte Tests, CI und Code Review zählen NICHT als Ingame-Verifikation.
Regeln und Eintragen von Ergebnissen: [PaTiAdmin/docs/TESTING.md](https://github.com/patpaskoch/PaTiAdmin/blob/main/docs/TESTING.md#in-game-test-files).

Neues PaTiGroup (Party Awareness, 2026-10-02). Die IDs `PT-GROUP-001…199` gehörten der früheren PaTiGroup-Implementierung
(heute PaTiLead, dort als RETIRED archiviert) und werden nie wiederverwendet. Neue Tests beginnen bei `PT-GROUP-200`.

## Legende

- [ ] offen / noch nicht bestätigt
- [x] vom Owner im echten Client bestätigt
- ❌ FAIL = im echten Client fehlgeschlagen
- 🔧 FIX IMPLEMENTED = Codefix vorhanden, Retest noch offen
- ✅ VERIFIED = erfolgreich im echten Client bestätigt
- MANUAL RETEST REQUIRED = erneuter Test notwendig

## Installation / Laden

- [ ] PT-GROUP-200 Fresh Install aus dem Release-ZIP: genau ein Ordner `PaTiGroup/`, Addon lädt allein
- [ ] PT-GROUP-201 Alten Ordner `PaTiGroup/` (Marker-Addon) vollständig ersetzt: kein Lua-Fehler, Standard-Einstellungen,
  keine alten Marker-Buttons
- [ ] PT-GROUP-202 PaTiGroup erscheint in der AddOn-Liste mit Beschreibung („Gruppe im Blick: …“)
- [ ] PT-GROUP-203 Icon in der AddOn-Liste korrekt (Gruppenmotiv), keine weiße oder fehlende Textur
- [ ] PT-GROUP-204 Login und `/reload` ohne Lua-Fehler
- [ ] PT-GROUP-205 `/pg debug`: APIs und pro Gruppenmitglied Rolle, Zustand und Ziel-Token (Ausgabe melden)

## Fenster

- [ ] PT-GROUP-210 `/pg`, `/ptg`, `/patigroup` und `/pg toggle` blenden das Fenster ein und aus; `/pg show`, `/pg hide`
- [ ] PT-GROUP-211 Am Header verschieben; Position bleibt nach `/reload`
- [ ] PT-GROUP-212 Lock/Unlock (••• und `/pg lock` / `unlock`): gesperrt nicht verschiebbar
- [ ] PT-GROUP-213 Größe (Scale) und Panel-Deckkraft 30–100 % wirken (Deckkraft: nur der Hintergrund)
- [ ] PT-GROUP-214 ••• → Einklappen: nur der Header bleibt; Ausklappen; bleibt nach `/reload`
- [ ] PT-GROUP-215 Test Mode `/pg test`: Tank Patrick, Heiler Stefanie, Tankziel mit Totenschädel „Dunkler Kultist“,
  „1 Tank · 1 Heal · 3 DD“, TEST-Badge
- [ ] PT-GROUP-216 `/pg reset` setzt die Position zurück; „Standard wiederherstellen“ setzt Einstellungen zurück
- [ ] PT-GROUP-217 deDE: alle Texte deutsch, keine Schlüsselnamen, nichts abgeschnitten (auch lange Namen); enUS nach
  Sprachwahl

## Gruppe

- [ ] PT-GROUP-220 Solo: „Nicht in einer Gruppe“, sonst nichts
- [ ] PT-GROUP-221 Gruppe beitreten / verlassen: Anzeige wechselt ohne `/reload`
- [ ] PT-GROUP-222 Tank wird mit Namen erkannt (Rolle über Rollencheck/Gruppensuche gesetzt)
- [ ] PT-GROUP-223 Heiler wird mit Namen erkannt
- [ ] PT-GROUP-224 Rollenzeile stimmt (Tank / Heal / DD) und ändert sich bei Rollenwechsel
- [ ] PT-GROUP-225 Ohne zugewiesene Rollen: „niemand mit dieser Rolle“ und „n ohne Rolle“ — keine geratene Rolle
- [ ] PT-GROUP-226 Heiler tot → „tot“ (rot); wiederbelebt → verschwindet
- [ ] PT-GROUP-227 Heiler offline → „offline“ (rot)
- [ ] PT-GROUP-228 Schlachtzug: Tank, Heiler und Rollen stimmen (falls verfügbar)

## Tankziel

- [ ] PT-GROUP-230 Du bist Tank: dein Ziel erscheint als Tankziel
- [ ] PT-GROUP-231 Anderer Spieler ist Tank: sein Ziel erscheint als Tankziel
- [ ] PT-GROUP-232 Tank ohne Ziel: „kein Ziel“
- [ ] PT-GROUP-233 Tankziel wechselt → Anzeige wechselt sofort (ohne `/reload`)
- [ ] PT-GROUP-234 Tankziel mit Raidmarker: das Marker-Icon steht vor dem Namen; Marker ändern/entfernen → Anzeige folgt
- [ ] PT-GROUP-235 Kein Tank in der Gruppe: „kein Tank in der Gruppe“

## Combat / Sicherheit

- [ ] PT-GROUP-240 Im Kampf: Anzeige aktualisiert sich (Tankziel, Heiler tot), kein Lua-Fehler
- [ ] PT-GROUP-241 Keine `ADDON_ACTION_BLOCKED` / `ADDON_ACTION_FORBIDDEN`; `taint.log` ohne PaTiGroup-Eintrag
- [ ] PT-GROUP-242 PaTiGroup wählt, markiert oder zaubert nie etwas

## Combined

- [ ] PT-GROUP-250 Zusammen mit allen PaTi-Addons geladen (auch PaTiLead): kein Lua-Fehler, `/pg` antwortet nur PaTiGroup
- [ ] PT-GROUP-251 PaTiSuite: „Group“ erscheint getrennt von „Lead“; Ein-/Ausblenden wirkt nur auf PaTiGroup; Zustand
  bleibt nach `/reload`
