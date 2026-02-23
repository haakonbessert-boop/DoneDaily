# DoneDaily

DoneDaily ist eine iOS-App für fokussiertes Habit-Tracking mit lokalem First-Ansatz: schnell abhaken, sauber auswerten, keine unnötige Gamification.

## Highlights

- **Heute-Flow mit zwei Modi**: `Übersicht` und `Fokus`
- **Habit-Tracking in zwei Typen**:
  - `Einmal pro Tag` (binär)
  - `Mehrmals pro Tag` mit Tagesziel (z. B. Wasser `0/8`)
- **Streak-Logik mit Zielerfüllung**: zählt nur bei vollständigem Tagesziel
- **Gruppen für Übersicht**: Habits gruppieren, sortieren und im Alltag schneller finden
- **Quick Add + Full Add**: schneller Einstieg oder vollständige Konfiguration
- **Insights (7/30/90 Tage)**:
  - Completion-Trend
  - Weekday-Pattern
  - Heatmap
  - Group Insights
- **Reminder-System** (lokal): Muster, Uhrzeit, Wochentage, sanfte Texte
- **Export/Import**: CSV + JSON inklusive Tracking-Typ und Tagesziel
- **Dev-Reset in Debug**: Onboarding + Daten für Entwicklung schnell zurücksetzen

## Tech Stack

- **UI**: SwiftUI
- **Persistenz**: SwiftData
- **Notifications**: UserNotifications (`UNUserNotificationCenter`)
- **State/Settings**: `ObservableObject` + `UserDefaults`
- **Diagnostics**: OSLog-basierte Fehler-/Performance-Utilities

## Projektstruktur

- `DoneDaily/App`  
  App-Entry, Container-Aufbau, Root-Navigation
- `DoneDaily/Features`  
  UI-Features: `Today`, `Habits`, `Stats`, `Settings`, `Onboarding`
- `DoneDaily/Models`  
  SwiftData-Modelle (`HabitGroup`, `Habit`, `HabitLog`)
- `DoneDaily/Services`  
  Reminder, Persistenz, Settings, Diagnostics
- `DoneDaily/Views`  
  Reusable Components + Design-System
- `DoneDailyTests` / `DoneDailyUITests`  
  Unit- und UI-Tests

## Voraussetzungen

- Xcode 16+
- iOS 26 Simulator Runtime (empfohlen)

## Build

```bash
xcodebuild -project DoneDaily.xcodeproj -scheme DoneDaily -destination "platform=iOS Simulator,name=iPhone 17,OS=26.2" CODE_SIGNING_ALLOWED=NO build
```

## Tests

Schneller Smoke-Check:

```bash
./scripts/release_smoke.sh
```

Gezielter Unit-Test-Run:

```bash
xcodebuild -project DoneDaily.xcodeproj -scheme DoneDaily -destination "platform=iOS Simulator,name=iPhone 17,OS=26.2" -parallel-testing-enabled NO -maximum-concurrent-test-simulator-destinations 1 -only-testing:DoneDailyTests test
```

## TestFlight Build

```bash
./scripts/build_testflight.sh
```

## Datenschutz

- Privacy Manifest: `DoneDaily/Resources/PrivacyInfo.xcprivacy`
- Reminder-Verarbeitung und Tracking laufen lokal auf dem Gerät

## Dokumentation

- Migration Notes: `MIGRATION_NOTES.md`
- Release Checklist: `RELEASE_CHECKLIST.md`
- Changelog: `CHANGELOG.md`
