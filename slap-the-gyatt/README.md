# 👋 Slap the Gyatt 2.0

Ein komplettes Roblox-Simulator-Spiel: Slappe die Gyatts, sammle **Slaps** und **Gems**,
verbessere deine Hand, schlüpfe Pets, schalte 6 Welten frei und werde der Stärkste!

## 🚀 Starten

1. **`SlapTheGyatt.rbxlx`** herunterladen.
2. In Roblox Studio öffnen (Doppelklick oder *Datei → Öffnen*).
3. **▶ Play** drücken. Fertig!

Die ganze Welt (über 1700 Teile), alle Gyatts, Eier, Menüs und Effekte werden beim
Start von den Skripten gebaut. Du musst nichts selbst bauen.

**Speichern in Studio:** Spiel veröffentlichen und unter
*Game Settings → Security → Enable Studio Access to API Services* einschalten.
Ohne das läuft alles, nur der Fortschritt wird nicht gespeichert.

Mit Rojo: `rojo serve` (die `default.project.json` liegt in diesem Ordner).

## 🎮 Was alles drin ist

### Slappen
- Klicken (oder am Handy tippen) mit der Hand = Slap
- **Krits** (x3) und seltene **MEGA-Krits** (x30) mit Regenbogen-Effekt
- **Combo-System**: schnell hintereinander slappen = bis zu +225 % Slaps
- Schadenszahlen, Partikel, Kamera-Wackeln und Sounds
- Die Gyatts **hüpfen, schauen dich an, erschrecken sich** (Mund wird zum „O“) und wackeln bei Treffern

### 6 Welten mit 12 Gyatts
| Zone | Gyatts | Deko |
|---|---|---|
| 1 Gyatt-Wiese | Baby Gyatt, Big Gyatt | Bäume, Blumen, Büsche |
| 2 Wüsten-Gyatt | Kaktus Gyatt, Pharao Gyatt | Kakteen, Palmen, Pyramiden |
| 3 Eis-Gyatt-Land | Schnee Gyatt, Frost Gyatt | Eiszapfen, Tannen, Schneemänner |
| 4 Lava-Gyatt-Vulkan | Magma Gyatt, Inferno Gyatt | Lavaseen, Vulkane mit Feuer |
| 5 Wolken-Gyatt-Himmel | Engel Gyatt, Himmels Gyatt | Wolken, Goldsäulen, Regenbogen |
| 6 Galaxie-Gyatt-Weltall | Alien Gyatt, GYATT GOTT | Sterne, Planeten, Kristalle |

Jeder Gyatt hat Augen, Pupillen, Augenbrauen, Bäckchen, einen Mund und Accessoires
(Schleife, Sonnenbrille, Cowboyhut, Schal, Hörner, Heiligenschein, Antennen, Krone).
Jede Zone hat eigenes Licht und eigene Stimmung (in der Galaxie ist Nacht).

### ⭐ Goldener Gyatt (Event)
Alle 4–7 Minuten erscheint ein goldener Gyatt mit riesigen Belohnungen und Gems. Ein Banner zeigt den Countdown.

### ✋ 12 Hände
Holz → Stein → Eisen → Gold → Smaragd → Diamant → Frost → Lava → Wolken → Galaxie → Regenbogen → **Gyatt-Gott-Hand**.
Mit Glitzer-, Feuer-, Nebel- und Regenbogen-Effekten. Die Hand wird mit jedem Stärke-Level größer.

### 🛒 6 Upgrades
Hand-Stärke, Slap-Tempo, Reichweite, Krit-Glück, Slap-Gier, Combo-Meister (mit „MAX kaufen“-Knopf).

### 🐾 Pets
- 7 Eier, 28 Pets in 5 Seltenheiten (Gewöhnlich bis Mythisch)
- Ei-Öffnen-Animation, 1x oder 3x öffnen
- Pets folgen dir und schweben hinter dir her (Hund, Katze, Hase, Drache, Einhorn, Alien, Roboter, Wal, Geist …)
- Beste ausrüsten, ablegen, löschen

### 💎 Gems & Gem-Shop
Auto-Slap, mehr Pet-Plätze, mehr Inventar, 2x Slaps, 2x Schaden, Ei-Glück.

### 🎁 Belohnungen
- **Tägliche Belohnung** mit 7-Tage-Serie
- **3 tägliche Quests** (jeden Tag neu)
- **Codes**: `GYATT`, `SLAP`, `RELEASE`, `BIGHAND`, `LUCKY`

### ♻️ Rebirth
Setzt Slaps, Upgrades und Zonen zurück. Dafür gibt's für immer mehr Slaps, mehr Schaden und Gems.

### ⚔️ PvP-Slap-Arena
Im Startbereich: Slappe andere Spieler weg!

### Und noch mehr
- 🏆 Globale Bestenlisten (meiste Slaps, meiste Rebirths)
- 🗺️ Teleport zu allen freigeschalteten Zonen
- Tutorial-Pfeil für neue Spieler
- ⚙️ Optionen (Sounds, Schadenszahlen, Kamera-Wackeln, fremde Pets) und Statistik
- Speichern im DataStore (automatisch, beim Verlassen und beim Herunterfahren)
- Alle Käufe und Slaps werden **auf dem Server geprüft**. Mit Cheats bekommt man nichts geschenkt.
- Funktioniert am PC, Handy und Tablet

## 📁 Aufbau

```
src/shared/            -> ReplicatedStorage.SlapShared
  Config.lua             alle Spielwerte (Preise, Leben, Pets, Codes ...)
  Calc.lua               alle Formeln (Server + Client)
src/server/SlapServer/ -> ServerScriptService.SlapServer (Script + Module)
  World, Gyatts, Hands, Combat, Shop, Pets, Rewards, Leaderboards, Data, Remotes
src/client/SlapClient/ -> StarterPlayerScripts.SlapClient (LocalScript + Module)
  UI, Hud, Menus, Effects, WorldFx, PetsFx, Hatch
```

## ✏️ Werte ändern

Alles steht in `src/shared/Config.lua`. Danach die Place-Datei neu bauen:

```
python3 tools/build_place.py
```
