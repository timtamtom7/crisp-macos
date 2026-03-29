import SwiftUI

struct MacCaptureListView: View {
    @StateObject private var notesStore = NotesStore()
    @State private var selectedNote: CaptureNote?
    @State private var showingDetail = false
    @State private var topicInsights: [TopicInsight] = []
    @State private var selectedInsight: TopicInsight?
    @State private var showingInsightNotes = false

    private let aiService = AIVoiceService.shared

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

            // Insight filter panel
            if showingInsightNotes {
                insightNotesOverlay
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            computeInsights()
        }
        .onChange(of: notesStore.notes) { _, _ in
            computeInsights()
        }
    }

    // MARK: - Auto-Organization Section

    private var insightsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("You mentioned...")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(DesignTokens.textSecondary)
                .textCase(.uppercase)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(topicInsights.prefix(5)) { insight in
                        InsightChip(insight: insight) {
                            selectedInsight = insight
                            showingInsightNotes = true
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .background(DesignTokens.surface.opacity(0.5))
    }

    private var notesList: some View {
        ScrollView {
            LazyVStack(spacing: 1) {
                // Topic clusters section (auto-organization)
                if !topicInsights.isEmpty {
                    insightsSection
                    Divider()
                        .background(DesignTokens.surface)
                }

                ForEach(filteredNotes) { note in
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

    private var filteredNotes: [CaptureNote] {
        notesStore.notes
    }

    // MARK: - Insight Notes Overlay

    private var insightNotesOverlay: some View {
        ZStack(alignment: .topTrailing) {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showingInsightNotes = false
                    }
                }

            if let insight = selectedInsight {
                insightPanel(insight: insight)
            }
        }
    }

    private func insightPanel(insight: TopicInsight) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Panel header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(insight.insightText)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(DesignTokens.textPrimary)
                    Text("\(insight.noteIds.count) notes")
                        .font(.system(size: 11))
                        .foregroundColor(DesignTokens.textSecondary)
                }
                Spacer()
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showingInsightNotes = false
                    }
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(DesignTokens.textSecondary)
                        .frame(width: 28, height: 28)
                        .background(DesignTokens.surface)
                        .clipShape(Circle())
                }
            }
            .padding(16)

            Divider()
                .background(DesignTokens.surface)

            // Matching notes
            ScrollView {
                LazyVStack(spacing: 1) {
                    ForEach(notesStore.notes.filter { insight.noteIds.contains($0.id) }) { note in
                        InsightNoteRow(note: note) {
                            selectedNote = note
                            showingInsightNotes = false
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
        .frame(width: 360, height: 480)
        .background(DesignTokens.background)
        .transition(.move(edge: .trailing))
    }

    // MARK: - Helpers

    private func computeInsights() {
        let voiceNotes = notesStore.notes.map { VoiceNote(from: $0) }
        topicInsights = aiService.analyzeRecurringTopics(notes: voiceNotes, thisWeek: true)
    }

    // MARK: - Empty State

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

    // MARK: - Detail Overlay

    private func detailOverlay(note: CaptureNote) -> some View {
        ZStack(alignment: .topTrailing) {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showingDetail = false
                    }
                }
                .accessibilityLabel("Close detail panel")
                .accessibilityHint("Tap to dismiss the detail view")

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

// MARK: - Insight Chip

struct InsightChip: View {
    let insight: TopicInsight
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(insight.topic)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(DesignTokens.accent)
                Text("\(insight.mentionCount)×")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(DesignTokens.textPrimary)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(DesignTokens.accent.opacity(0.2))
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(DesignTokens.surface)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Insight Note Row

struct InsightNoteRow: View {
    let note: CaptureNote
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(note.transcription)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(DesignTokens.textPrimary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

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
        .buttonStyle(.plain)
    }
}

// MARK: - Note Row

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
