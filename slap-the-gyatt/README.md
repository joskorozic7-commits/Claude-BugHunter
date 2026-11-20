# 👋 Slap the Gyatt

Ein komplettes Roblox-Spiel: Slappe die Gyatts mit deiner Hand, sammle **Slaps**
und verbessere deine Hand im Shop, um immer stärkere Gyatts zu besiegen.

## So startest du das Spiel (am einfachsten)

1. Lade **`SlapTheGyatt.rbxlx`** herunter.
2. Doppelklick darauf (oder in Roblox Studio: *Datei → Öffnen*).
3. Oben auf **▶ Play** drücken. Fertig!

Die Arena, die Gyatts, die Hand und das ganze Menü werden beim Start automatisch
von den Skripten gebaut. Du musst nichts selbst bauen.

**Speichern in Studio testen:** Spiel veröffentlichen, dann
*Game Settings → Security → Enable Studio Access to API Services* einschalten.
Ohne das funktioniert alles, nur der Fortschritt wird nicht gespeichert.

### Alternativ: Skripte von Hand einfügen

| Datei | Wohin in Studio | Typ | Name |
|---|---|---|---|
| `src/shared/SlapConfig.lua` | ReplicatedStorage | ModuleScript | `SlapConfig` |
| `src/server/SlapServer.server.lua` | ServerScriptService | Script | `SlapServer` |
| `src/client/SlapClient.client.lua` | StarterPlayer → StarterPlayerScripts | LocalScript | `SlapClient` |

Die Namen müssen genau so geschrieben sein.

### Alternativ: mit Rojo

```
rojo serve
```
(`default.project.json` liegt in diesem Ordner.)

## So spielt man

- Du startest mit der **Holz-Hand** (sie ist automatisch ausgerüstet).
- Lauf zu einem Gyatt und **klicke** (oder tippe am Handy), um ihn zu slappen.
- Jeder Slap gibt dir **Slaps** (die Währung). Wer beim Besiegen geholfen hat, bekommt einen **Bonus**.
- Im **🛒 Shop** verbesserst du deine Hand:

| Upgrade | Wirkung | Max |
|---|---|---|
| 💪 Hand-Stärke | mehr Schaden, die Hand wird größer und bekommt neues Material | 50 |
| ⚡ Slap-Tempo | kürzere Wartezeit zwischen Slaps | 25 |
| 📏 Reichweite | du triffst aus größerer Entfernung | 20 |
| 🍀 Krit-Glück | Chance auf einen kritischen Slap (x3 Schaden) | 25 |
| 💰 Slap-Gier | mehr Slaps pro Treffer | 40 |

- Hand-Stufen: Holz → Stein → Eisen → Gold → Diamant → Regenbogen.
- Gyatts: Baby Gyatt → Big Gyatt (💪 Lv 5) → Mega Gyatt (Lv 12) → King Gyatt (Lv 22) → Gyatt Gott (Lv 35).
- **♻️ Rebirth**: setzt Slaps und Upgrades zurück, gibt dir aber für immer +50 % Slaps.

## Was alles drin ist

- Jeder Slap wird auf dem **Server geprüft** (Wartezeit, Reichweite, Stärke). Mit Exploits kann man nicht schummeln.
- **DataStore**: der Spielstand wird automatisch alle 2 Minuten, beim Verlassen und beim Herunterfahren des Servers gespeichert. Wenn das Laden fehlschlägt, wird nichts überschrieben.
- Mehrspieler: alle sehen die Schadenszahlen, Lebensbalken und Siege der anderen.
- Funktioniert am PC, Handy und Tablet.

## Werte ändern

Alle Zahlen (Preise, Schaden, Leben der Gyatts, Rebirth-Kosten …) stehen in
`src/shared/SlapConfig.lua`. Danach die Place-Datei neu bauen:

```
python3 tools/build_place.py
```
