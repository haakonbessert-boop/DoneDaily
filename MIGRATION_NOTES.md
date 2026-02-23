# SwiftData Migration Notes

## Stand 2026-02-23

`Habit` wurde um folgende Felder erweitert:

- `categoryRawValue`
- `notes`
- `isArchived`
- `isPaused`
- `pausedUntil`

## Strategie

- Für additive Felder mit sinnvollen Default-Werten wird Lightweight Migration genutzt.
- Bei Breaking-Änderungen (Umbenennung/Typwechsel) soll ein expliziter Migrationsschritt vorbereitet werden, bevor die App-Version erhöht wird.
- Vor Release immer mit realen Alt-Daten testen:
1. Vorversion starten und Beispieldaten anlegen.
2. Neue Version darüber installieren.
3. Start, Today-Ansicht, Habits-Liste, Reminder-Resync und Stats prüfen.

## Rollback

- Falls Migration fehlschlägt: Build nicht ausrollen, Version zurücksetzen, Migrationspfad ergänzen.
