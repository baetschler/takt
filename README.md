# Takt

Intervall-Timer für Calisthenics, native iOS-App (SwiftUI, iOS 17+). Eigener Ersatz für Timer Plus.

- Workouts aus Blöcken, jeder Block mit Runden und Schritten (Übung/Pause)
- Pause zwischen Runden und nach jedem Block, Vorbereitungszeit
- Pieptöne in den letzten 3 Sekunden, Signal beim Phasenwechsel, deutsche Sprachansage mit der besten installierten Stimme (wählbar, mit Probehören)
  („Runde 2 von 4. Klimmzüge. 40 Sekunden“, „Pause. Danach Dips“)
- Läuft bei gesperrtem Bildschirm weiter und mischt sich über laufende Musik
- Display bleibt während des Trainings an
- Zurück/Überspringen/Pause, Tippen auf den Ring pausiert
- Workouts liegen lokal als JSON in der App, ohne Account und ohne Cloud

## Aufs iPhone bringen (kostenlose Apple-ID)

1. Xcode aus dem App Store installieren, einmal starten, iOS-Plattform laden lassen.
2. `Takt.xcodeproj` öffnen.
3. Xcode → Settings → Accounts: Apple-ID hinzufügen.
4. Target „Takt“ → Signing & Capabilities → Team: „(Persönliches Team)“ wählen.
   Ist die Bundle-ID schon vergeben, `ai.kaibachler.takt` leicht ändern.
5. iPhone per Kabel anschließen, oben als Ziel wählen, ⌘R.
6. Auf dem iPhone: Einstellungen → Datenschutz & Sicherheit → Entwicklermodus an (Neustart),
   dann Allgemein → VPN & Geräteverwaltung → dem Entwicklerzertifikat vertrauen.

Mit kostenloser Apple-ID läuft die App **7 Tage**. Danach startet sie nicht mehr: iPhone anschließen
und erneut ⌘R. Die Workouts bleiben dabei erhalten.

## Entwicklung

Das Xcode-Projekt wird aus `project.yml` erzeugt ([XcodeGen](https://github.com/yonaskolb/XcodeGen)).
Nach Änderungen an Dateien oder Einstellungen:

```bash
xcodegen generate
```

Version: `MARKETING_VERSION` in `project.yml`.

| Datei | Inhalt |
|---|---|
| `Models.swift` | Workout/Block/Step, Umwandlung in eine lineare Phasenliste |
| `WorkoutRunner.swift` | Timer-Engine (Enddatum-basiert, driftfrei) |
| `CueEngine.swift` | Töne (zur Laufzeit erzeugt), Sprachausgabe, Audio-Session für den Hintergrund |
| `WorkoutStore.swift` | Speichern als JSON |
| `*View.swift` | Oberfläche |
