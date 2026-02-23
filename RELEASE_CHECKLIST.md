# DoneDaily Release Checklist

## Branding
- [x] Platzhalter-App-Icon generiert (`AppIcon-1024.png`)
- [ ] Finales Brand-App-Icon ersetzen
- [x] Launch Screen ist aktiv (Xcode LaunchScreen Generation)

## Privacy & Permissions
- [x] Privacy Manifest vorhanden: `DoneDaily/Resources/PrivacyInfo.xcprivacy`
- [x] Benachrichtigungen nur per Opt-in (`SettingsView` + Reminder-Flow)

## Versioning
- [x] `MARKETING_VERSION` gesetzt
- [x] `CURRENT_PROJECT_VERSION` gesetzt

## Quality Gate
- [ ] Unit Tests in Test-Target einhängen und ausführen
- [ ] UI Tests in UI-Test-Target einhängen und ausführen
- [ ] Manual Smoke Test auf Device

## TestFlight
1. Xcode: `Product > Archive`
2. Organizer: `Distribute App > App Store Connect > Upload`
3. Build in App Store Connect prüfen
4. Interne Tester hinzufügen
