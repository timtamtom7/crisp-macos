import SwiftUI

struct MacContentView: View {
    @State private var selectedTab: Tab = .capture

    enum Tab {
        case capture
        case library
    }

    var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            detailContent
        }
        .frame(minWidth: 700, idealWidth: 900, minHeight: 500, idealHeight: 650)
        .background(DesignTokens.background)
    }

    private var sidebar: some View {
        VStack(spacing: 0) {
            // App title
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Circle()
                        .fill(DesignTokens.accent)
                        .frame(width: 8, height: 8)
                    Text("Crisp")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(DesignTokens.textPrimary)
                }
                Text("Just talk.")
                    .font(.system(size: 11))
                    .foregroundColor(DesignTokens.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.vertical, 20)

            Divider()
                .background(DesignTokens.surface)

            // Tab buttons
            VStack(spacing: 2) {
                TabButton(
                    title: "Capture",
                    icon: "mic.fill",
                    isSelected: selectedTab == .capture
                ) {
                    selectedTab = .capture
                }
                .accessibilityLabel("Capture tab")
                .accessibilityHint("Navigate to voice recording")

                TabButton(
                    title: "Library",
                    icon: "list.bullet",
                    isSelected: selectedTab == .library
                ) {
                    selectedTab = .library
                }
                .accessibilityLabel("Library tab")
                .accessibilityHint("Navigate to your saved recordings")
            }
            .padding(.horizontal, 8)
            .padding(.top, 8)

            Spacer()
        }
        .frame(width: 180)
        .background(DesignTokens.surface)
    }

    @ViewBuilder
    private var detailContent: some View {
        switch selectedTab {
        case .capture:
            MacRecordView()
        case .library:
            MacCaptureListView()
        }
    }
}

struct TabButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .medium))
                    .frame(width: 18)

                Text(title)
                    .font(.system(size: 13, weight: .medium))

                Spacer()
            }
            .foregroundColor(isSelected ? DesignTokens.textPrimary : DesignTokens.textSecondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? DesignTokens.accent.opacity(0.15) : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }
}
