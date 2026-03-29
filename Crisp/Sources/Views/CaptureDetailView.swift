import SwiftUI
import AVFoundation

struct CaptureDetailView: View {
    let note: CaptureNote
    let audioURL: URL
    let onDelete: () -> Void
    let onClose: () -> Void

    @StateObject private var playerService = AudioPlayerService()
    @State private var isEditing = false
    @State private var editedText: String = ""
    @State private var showCopied = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(DesignTokens.textSecondary)
                        .frame(width: 32, height: 32)
                        .background(DesignTokens.surface)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)

                Spacer()

                Text(note.formattedDate)
                    .font(.system(size: 13))
                    .foregroundColor(DesignTokens.textSecondary)

                Spacer()

                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(DesignTokens.error)
                        .frame(width: 32, height: 32)
                        .background(DesignTokens.surface)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)

            Divider()
                .background(DesignTokens.surface)

            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Transcription
                    if isEditing {
                        TextEditor(text: $editedText)
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(DesignTokens.textPrimary)
                            .scrollContentBackground(.hidden)
                            .background(DesignTokens.surface)
                            .frame(minHeight: 120)
                            .cornerRadius(10)
                    } else {
                        Text(note.transcription)
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(DesignTokens.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    // Audio playback (if available)
                    if note.audioFileName != nil {
                        audioPlayerCard
                    }

                    // Metadata
                    HStack(spacing: 16) {
                        if note.duration > 0 {
                            Label(note.formattedDuration, systemImage: "waveform")
                                .font(.system(size: 13))
                                .foregroundColor(DesignTokens.textSecondary)
                        }
                    }
                }
                .padding(20)
            }

            Spacer()

            // Bottom actions
            HStack(spacing: 12) {
                // Copy button
                Button(action: copyToClipboard) {
                    HStack(spacing: 6) {
                        Image(systemName: showCopied ? "checkmark" : "doc.on.doc")
                            .font(.system(size: 12))
                        Text(showCopied ? "Copied" : "Copy")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(DesignTokens.textPrimary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(DesignTokens.surface)
                    .cornerRadius(10)
                }
                .buttonStyle(.plain)

                // Edit button
                Button(action: {
                    if isEditing {
                        isEditing = false
                    } else {
                        editedText = note.transcription
                        isEditing = true
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: isEditing ? "checkmark" : "pencil")
                            .font(.system(size: 12))
                        Text(isEditing ? "Done" : "Edit")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(DesignTokens.textPrimary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(DesignTokens.accent.opacity(0.2))
                    .cornerRadius(10)
                }
                .buttonStyle(.plain)

                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(DesignTokens.surface)
        }
    }

    private var audioPlayerCard: some View {
        HStack(spacing: 12) {
            // Play/Pause button
            Button(action: {
                playerService.togglePlayback(url: audioURL)
            }) {
                Image(systemName: playerService.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 14))
                    .foregroundColor(DesignTokens.background)
                    .frame(width: 40, height: 40)
                    .background(DesignTokens.accent)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)

            // Progress bar
            VStack(alignment: .leading, spacing: 4) {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(DesignTokens.textSecondary.opacity(0.3))
                            .frame(height: 4)

                        RoundedRectangle(cornerRadius: 2)
                            .fill(DesignTokens.accent)
                            .frame(
                                width: geometry.size.width * progress,
                                height: 4
                            )
                    }
                }
                .frame(height: 4)

                Text("\(formatTime(playerService.currentTime)) / \(formatTime(playerService.duration))")
                    .font(.system(size: 11))
                    .foregroundColor(DesignTokens.textSecondary)
            }

            Spacer()
        }
        .padding(14)
        .background(DesignTokens.surface)
        .cornerRadius(14)
    }

    private var progress: CGFloat {
        guard playerService.duration > 0 else { return 0 }
        return CGFloat(playerService.currentTime / playerService.duration)
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    private func copyToClipboard() {
        UIPasteboard.general.string = note.transcription
        withAnimation {
            showCopied = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation {
                showCopied = false
            }
        }
    }
}
