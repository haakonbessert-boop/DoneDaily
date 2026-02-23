# DoneDaily Release Checklist

## Branding
- [x] App-Icon aktualisiert (`AppIcon-1024.png`)
- [ ] Finales Marketing-Icon aus Brand-Team übernehmen (optional Austausch)
- [x] Launch Screen ist aktiv (Xcode LaunchScreen Generation)

## Privacy & Permissions
- [x] Privacy Manifest vorhanden: `DoneDaily/Resources/PrivacyInfo.xcprivacy`
- [x] Benachrichtigungen nur per Opt-in (`SettingsView` + Reminder-Flow)

## Versioning
- [x] `MARKETING_VERSION` gesetzt
- [x] `CURRENT_PROJECT_VERSION` gesetzt

## Quality Gate
- [x] Unit-Testfälle erweitert (`DoneDailyTests/*`)
- [x] UI-Smoke-Testfälle erweitert (`DoneDailyUITests/DoneDailyUITests.swift`)
- [x] Smoke-Script vorhanden (`scripts/release_smoke.sh`)
- [x] Smoke-Script robust gegen Simulator-Fehler gemacht (`simctl shutdown/erase`, serial test execution, xcresult output)
- [x] Smoke-Workflow in CI angelegt (`.github/workflows/ios-smoke.yml`)
- [ ] Manual Smoke Test auf Device

## Reliability
- [x] SwiftData-Recovery mit Store-Artefakt-Cleanup (`SwiftDataStoreRecovery`)
- [x] Reminder-Resync-Service testbar gemacht (`syncAllNow`)
- [x] Export-Service mit echten Dateien (`DataExportService`)

## Accessibility & UX
- [x] Progress-Elemente mit Accessibility Labels/Values
- [x] Reduce-Motion berücksichtigt in zentralen Transitions
- [x] Onboarding mit Wochenstart + Starter-Habits + Reminder-Nudge

## TestFlight
1. Xcode: `Product > Archive`
2. Organizer: `Distribute App > App Store Connect > Upload`
3. Build in App Store Connect prüfen
4. Interne Tester hinzufügen
