import SwiftUI
import AVFoundation

struct RecordView: View {
    @StateObject private var voiceService = VoiceCaptureService()
    @StateObject private var notesStore = NotesStore()
    @State private var statusText = "Tap to record"
    @State private var showSaved = false
    @State private var isAuthorized = false
    @State private var recordingStartTime: Date?

    var body: some View {
        ZStack {
            DesignTokens.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Top bar
                HStack {
                    Spacer()
                    Text("Crisp")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(DesignTokens.textSecondary)
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)

                Spacer()

                // Waveform
                VStack(spacing: 20) {
                    WaveformView(
                        levels: voiceService.waveformLevels,
                        isAnimating: voiceService.isRecording,
                        barCount: 28
                    )
                    .frame(height: 80)
                    .padding(.horizontal, 40)

                    // Sound quality indicator
                    SoundQualityIndicator(
                        level: voiceService.currentLevel,
                        isRecording: voiceService.isRecording
                    )

                    // Status text
                    Text(statusText)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(DesignTokens.textSecondary)
                        .multilineTextAlignment(.center)
                }

                Spacer()

                // Transcription preview
                if !voiceService.transcription.isEmpty {
                    ScrollView {
                        Text(voiceService.transcription)
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(DesignTokens.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 24)
                    }
                    .frame(maxHeight: 120)
                    .padding(.horizontal, 20)
                }

                Spacer()

                // Record button
                VStack(spacing: 16) {
                    RecordButton(isRecording: voiceService.isRecording) {
                        handleRecordTap()
                    }
                    .disabled(!isAuthorized)
                    .accessibilityLabel(voiceService.isRecording ? "Stop recording" : "Start recording")
                    .accessibilityHint(voiceService.isRecording ? "Stops voice capture" : "Begins recording your voice")

                    if !isAuthorized {
                        Text("Microphone access required")
                            .font(.system(size: 13))
                            .foregroundColor(DesignTokens.textSecondary)
                    }
                }
                .padding(.bottom, 48)
            }

            // Saved confirmation overlay
            if showSaved {
                savedOverlay
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            checkAuthorization()
        }
    }

    private var savedOverlay: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 44))
                    .foregroundColor(DesignTokens.accent)

                Text("Saved")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(DesignTokens.textPrimary)
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(DesignTokens.surface)
            )
        }
        .transition(.opacity)
    }

    private func handleRecordTap() {
        if voiceService.isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }

    private func startRecording() {
        do {
            try voiceService.startRecording()
            recordingStartTime = Date()
            statusText = "Listening..."
        } catch {
            statusText = "Could not start recording"
        }
    }

    private func stopRecording() {
        guard let audioURL = voiceService.stopRecording() else {
            statusText = "Tap to record"
            return
        }

        statusText = "Saving..."
        let duration = recordingStartTime.map { Date().timeIntervalSince($0) } ?? 0

        Task {
            let text = await voiceService.transcribe(audioURL: audioURL)

            await MainActor.run {
                let note = CaptureNote(
                    transcription: text.isEmpty ? "Voice capture" : text,
                    audioFileName: audioURL.lastPathComponent,
                    duration: duration
                )
                notesStore.saveNote(note)
                voiceService.transcription = ""

                withAnimation {
                    showSaved = true
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                    withAnimation {
                        showSaved = false
                    }
                    statusText = "Tap to record"
                }
            }
        }
    }

    private func checkAuthorization() {
        Task {
            let micGranted = await withCheckedContinuation { continuation in
                AVAudioApplication.requestRecordPermission { granted in
                    continuation.resume(returning: granted)
                }
            }
            let speechGranted = await voiceService.requestAuthorization()

            await MainActor.run {
                isAuthorized = micGranted && speechGranted
                if !isAuthorized {
                    statusText = "Grant microphone access in Settings"
                }
            }
        }
    }
}

// MARK: - Sound Quality Indicator

struct SoundQualityIndicator: View {
    let level: Float
    let isRecording: Bool

    private var quality: Quality {
        guard isRecording else { return .idle }
        if level < 0.15 { return .low }
        if level < 0.45 { return .medium }
        return .high
    }

    enum Quality {
        case idle, low, medium, high

        var color: Color {
            switch self {
            case .idle: return DesignTokens.textSecondary.opacity(0.4)
            case .low: return DesignTokens.error
            case .medium: return DesignTokens.accentAmber
            case .high: return DesignTokens.accent
            }
        }

        var icon: String {
            switch self {
            case .idle: return "waveform"
            case .low: return "waveform.badge.exclamationmark"
            case .medium: return "waveform"
            case .high: return "waveform"
            }
        }

        var label: String {
            switch self {
            case .idle: return "Ready"
            case .low: return "Low"
            case .medium: return "Good"
            case .high: return "Excellent"
            }
        }
    }

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: quality.icon)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(quality.color)

            Text(quality.label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(quality.color)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            Capsule()
                .fill(quality.color.opacity(0.12))
        )
    }
}
