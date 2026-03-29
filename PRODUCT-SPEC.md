# Crisp — iOS App Spec

## Concept

Crisp is the fastest way to capture a thought. You open the app, you talk, it's transcribed and saved — that's it. No opening notes, no typing, no navigating. The app is designed around a single core interaction: one tap, then talk. The transcribed text appears in real-time as a moving waveform/gradient visual. When you stop talking, the text is saved. No friction. No thinking about where to put it. Just talk and it lives.

**Core mechanic:** Open → Talk → Transcribed + saved. One tap.

---

## Brand Identity

**Name:** Crisp  
**Tagline:** "Just talk."  
**Vibe:** Immediate, quiet, precise. Like a clean desk with a single notepad on it.

**Aesthetic direction:** iOS 26 glass. Deep black background (`#0d0d0e`), white text, single warm accent. The waveform is the visual centerpiece — a fluid gradient that moves as you speak. Everything else is minimal chrome.

**Reference:** Apple's Voice Memos, but designed with the restraint of Linear.

**Colors:**
- Background: `#0d0d0e`
- Surface: `#141416`
- Text primary: `#f5f5f7`
- Text secondary: `#8b8b8e`
- Accent: `#c8a97e` (warm gold — same family as Ghost Notes)
- Waveform gradient: warm gold → amber → soft orange

**Typography:**
- SF Pro (system)
- Transcription text: SF Pro, 20px, medium weight, high contrast
- UI labels: SF Pro, 13px

---

## App Structure

### Main Screen — Capture
The entire screen is the capture interface. Nothing else.

```
┌─────────────────────────────┐
│  [Settings]          [Done] │  ← Minimal top bar
│                             │
│                             │
│   ████████░░░░░░░░░░░░░   │  ← Waveform/gradient visualization
│   ████████████░░░░░░░░░░   │     (animated, moves as you speak)
│   █████████████████░░░░░   │
│                             │
│  "Just talk. I'm listening" │  ← Status text (changes as you speak)
│                             │
│   [Transcribed text         │  ← Real-time transcription appears here
│    appears here as you      │
│    speak...]                │
│                             │
│                             │
│           ●                 │  ← Large tap-to-record button
│                             │
└─────────────────────────────┘
```

### States:
1. **Idle:** "Tap to record" — button is idle
2. **Listening:** Button pulses, waveform animates, status "Listening..."
3. **Processing:** Brief "Saving..." state
4. **Saved:** Brief checkmark, then reset

### Navigation
- Bottom tab bar: **Capture** | **Library**
- Settings gear in top right of Capture screen

### Library Screen
List of all saved voice notes. Each row:
- Title (first few words of transcription)
- Date + time
- Duration
- Tap to play back + see full transcription

### Note Detail Screen
- Full transcription text
- Play audio button
- Copy text
- Delete
- Share

### Settings
- Siri & Dictation language (English, etc.)
- Auto-save on stop or require tap to confirm
- About / Version

---

## Key Interaction Design

### The Waveform Gradient
As the user speaks:
- An animated gradient bar (warm gold → amber → soft orange) fills from left to right, with a fluid wave pattern
- The amplitude/movement of the wave responds to voice amplitude (from Speech framework)
- When speech stops, the wave gently fades to idle

### Saving Flow
1. Tap record button → starts listening
2. Tap again → stops listening
3. Transcription freezes, brief "Saving..." → checkmark
4. Automatically navigates to Library or stays on Capture (setting)

### Keyboard Extension (Later Phase)
- A custom keyboard that shows a waveform + mic button
- Long-press mic → dictation starts → text appears in any text field
- Gradient animation while speaking
- Tap elsewhere to dismiss

---

## Technical Approach

**Framework:** SwiftUI (iOS 26 target)  
**Speech Recognition:** `SFSpeechRecognizer` (on-device, iOS 17+)  
**Audio Recording:** `AVAudioEngine`  
**Data Persistence:** `UserDefaults` for settings, local SQLite via `SQLite.swift` for notes  
**Design System:** iOS 26 glass (`ultraThinMaterial`, `regularMaterial`)

**Dependencies (Swift Package Manager):**
- `SQLite.swift` — for notes storage
- No other dependencies needed

---

## Pages / Screens

1. **CaptureView** — Main recording screen with waveform + transcription
2. **LibraryView** — List of all saved notes
3. **NoteDetailView** — Full note with playback
4. **SettingsView** — App settings

---

## iOS 26 Design Tokens

```swift
struct DesignTokens {
    static let background = Color(hex: "#0d0d0e")
    static let surface = Color(hex: "#141416")
    static let accent = Color(hex: "#c8a97e")
    static let textPrimary = Color(hex: "#f5f5f7")
    static let textSecondary = Color(hex: "#8b8b8e")
    
    static let radiusSm: CGFloat = 6
    static let radiusMd: CGFloat = 12
    static let radiusLg: CGFloat = 22
    
    static let spring = SwiftUI.Animation.spring(response: 0.35, dampingFraction: 0.85)
}
```

---

## Human Inputs Needed
- [ ] App Store developer account ($99/year)
- [ ] App icon (Crisp wordmark + waveform icon)
- [ ] App name "Crisp" availability check on App Store
- [ ] Optional: Local model integration (for offline transcription — iOS 17+ SFSpeechRecognizer supports on-device)
