import SwiftUI

struct MacCaptureListView: View {
    @StateObject private var notesStore = NotesStore()
    @State private var selectedNote: CaptureNote?
    @State private var showingDetail = false

    var body: some View {
        ZStack {
            DesignTokens.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Library")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(DesignTokens.textPrimary)
                    Spacer()
                    Text("\(notesStore.notes.count) captures")
                        .font(.system(size: 12))
                        .foregroundColor(DesignTokens.textSecondary)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)

                Divider()
                    .background(DesignTokens.surface)

                if notesStore.notes.isEmpty {
                    emptyState
                } else {
                    notesList
                }
            }

            // Detail panel
            if showingDetail, let note = selectedNote {
                detailOverlay(note: note)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "waveform")
                .font(.system(size: 40))
                .foregroundColor(DesignTokens.textSecondary.opacity(0.5))
            Text("No captures yet")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(DesignTokens.textSecondary)
            Text("Your voice notes will appear here")
                .font(.system(size: 13))
                .foregroundColor(DesignTokens.textSecondary.opacity(0.7))
            Spacer()
        }
    }

    private var notesList: some View {
        ScrollView {
            LazyVStack(spacing: 1) {
                ForEach(notesStore.notes) { note in
                    NoteRow(note: note)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedNote = note
                            withAnimation(.easeInOut(duration: 0.2)) {
                                showingDetail = true
                            }
                        }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
    }

    private func detailOverlay(note: CaptureNote) -> some View {
        ZStack(alignment: .topTrailing) {
            // Backdrop
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showingDetail = false
                    }
                }
                .accessibilityLabel("Close detail panel")
                .accessibilityHint("Tap to dismiss the detail view")

            // Detail panel
            MacCaptureDetailView(
                note: note,
                audioURL: notesStore.audioFileURL(for: note.audioFileName ?? ""),
                onDelete: {
                    notesStore.deleteNote(note)
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showingDetail = false
                    }
                },
                onClose: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showingDetail = false
                    }
                }
            )
            .frame(width: 400)
            .frame(maxHeight: .infinity)
            .background(DesignTokens.background)
            .transition(.move(edge: .trailing))
        }
    }
}

struct NoteRow: View {
    let note: CaptureNote

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(note.transcription)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(DesignTokens.textPrimary)
                    .lineLimit(2)

                HStack(spacing: 8) {
                    Text(note.formattedDate)
                        .font(.system(size: 11))
                        .foregroundColor(DesignTokens.textSecondary)

                    if note.duration > 0 {
                        Text("·")
                            .foregroundColor(DesignTokens.textSecondary)
                        Text(note.formattedDuration)
                            .font(.system(size: 11))
                            .foregroundColor(DesignTokens.textSecondary)
                    }
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(DesignTokens.textSecondary.opacity(0.5))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(DesignTokens.surface)
        )
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
    }
}
