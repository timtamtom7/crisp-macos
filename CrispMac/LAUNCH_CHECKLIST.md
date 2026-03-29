# CrispMac — Launch Checklist

## Pre-Launch

### App Store Assets
- [ ] App Store icons (1024×1024 master + all required sizes)
- [ ] Screenshots: 2880×1800 (Retina), for 13"/15"/16" MacBook display sizes
- [ ] App Store description finalized (see `Marketing/APPSTORE.md`)
- [ ] Tagline: "Speak. Think. Done."
- [ ] Category selected: Productivity
- [ ] Keywords list optimized (≤100 chars)
- [ ] Privacy policy URL ready
- [ ] Support URL ready
- [ ] Marketing version set to 1.0.0

### Entitlements & Capabilities
- [ ] App Sandbox enabled
- [ ] Microphone usage description in Info.plist
- [ ] Speech recognition usage description in Info.plist
- [ ] Hardened Runtime enabled
- [ ] Signing certificate provisioned (Developer ID for direct distribution OR App Store Connect)

### Code & UI
- [ ] All waveform animations smooth at 60fps
- [ ] Record button is visually prominent (72pt minimum touch target)
- [ ] Sound quality indicator visible during recording
- [ ] All accessibility labels and hints implemented
- [ ] Dark mode exclusively (matches brand)
- [ ] Window title bar hidden (`windowStyle(.hiddenTitleBar)`)
- [ ] Window resizability set (`windowResizability(.contentSize)`)
- [ ] App launches without console errors
- [ ] Microphone permission prompt appears on first launch
- [ ] Speech recognition permission prompt appears on first launch

### Build & Sign
- [ ] `xcodebuild` Release build succeeds with `CODE_SIGN_IDENTITY="-"`
- [ ] App bundle runs from DerivedData (no crashes on launch)
- [ ] Archive succeeds for distribution
- [ ] If App Store: upload to App Store Connect via Transporter
- [ ] If direct: code sign with Developer ID for notarization

### Testing
- [ ] Record button responds correctly (start/stop)
- [ ] Waveform animates during recording
- [ ] Transcription completes after stopping
- [ ] Note saves to library
- [ ] Library displays saved notes
- [ ] Detail view opens on note tap
- [ ] Edit saves modified text
- [ ] Delete removes note
- [ ] Copy to clipboard works
- [ ] Audio playback works
- [ ] Permissions denied state handled gracefully

### Post-Launch
- [ ] TestFlight beta (optional — if doing internal/external testing)
- [ ] App Store Connect build processing
- [ ] Submit for review
- [ ] Monitor TestFlight/external crashes
- [ ] Collect first user feedback

---

## Version History
| Version | Date | Notes |
|---------|------|-------|
| 1.0.0 | TBD | Initial release |
