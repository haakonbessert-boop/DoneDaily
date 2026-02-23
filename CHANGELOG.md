# Changelog

## Unreleased (2026-02-23)

### Added
- Onboarding-Auswahl für Wochenstart, Starter-Habits und Reminder-Opt-in.
- Fokusbereiche im Onboarding mit daraus abgeleiteten Habit-Vorschlägen im Habits-Screen.
- Datei-Export als CSV und JSON (`DataExportService`) inkl. ShareLink im Settings-Screen.
- SwiftData-Recovery-Helfer (`SwiftDataStoreRecovery`) und zugehörige Regression-Tests.
- Performance-Monitoring (`AppPerformanceMonitor`) für First-Render-Logging.
- Zusätzliche Unit-Tests: Settings, Export, Reminder-Sync, Store-Recovery.

### Changed
- iOS-nahe UI-Polishes (Large Titles, TabBar-Material, Haptics, Accessibility Labels).
- Insights erweitert um Vorperiodenvergleich und Habit-Drilldown.
- `release_smoke.sh` robustisiert (Simulator reset, serial testing, result bundle).
- Reminder-Sync testbar gemacht via `syncAllNow(...)` und injizierbarem Scheduler.

### Fixed
- SwiftData-Container-Recovery nutzt gezielte Store-Artefakt-Erkennung statt nur `default.store*`.
