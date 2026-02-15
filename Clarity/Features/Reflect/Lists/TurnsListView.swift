// TurnsListView.swift
import SwiftUI
import SwiftData

struct TurnsListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TurnEntity.recordedAt, order: .reverse) private var turns: [TurnEntity]

    @State private var deleteErrorMessage: String?
    @State private var showDeleteError: Bool = false

    @State private var showPasteSheet: Bool = false
    @State private var navigateToTurnID: UUID?

    var body: some View {
        NavigationStack {
            List {
                if turns.isEmpty {
                    ContentUnavailableView("No captures yet", systemImage: "mic")
                } else {
                    ForEach(turns) { t in
                        NavigationLink(value: t.id) {
                            row(t)
                                .contextMenu {
                                    if let text = transcriptPreview(for: t), !text.isEmpty {
                                        Button("Copy") {
#if os(iOS)
                                            UIPasteboard.general.string = text
#endif
                                        }
                                    }
                                    Button(t.isStarred ? "Unstar" : "Star") {
                                        toggleStar(t)
                                    }
                                }
                        }
                    }
                    .onDelete(perform: delete)
                }
            }
            .navigationTitle("Captures")
            .navigationDestination(for: UUID.self) { id in
                TurnDetailView(turnID: id)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showPasteSheet = true
                    } label: {
                        Image(systemName: "doc.on.clipboard")
                    }
                    .accessibilityLabel("Paste text")
                }
            }
            .sheet(isPresented: $showPasteSheet) {
                PasteTextTurnSheet { newID in
                    // Push to the new capture after creation
                    navigateToTurnID = newID
                }
            }
            .background(hiddenNavigationLink)
            .alert("Couldn’t delete capture", isPresented: $showDeleteError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(deleteErrorMessage ?? "Please try again.")
            }
        }
    }

    // Hidden link to trigger navigation reliably after sheet dismissal
    private var hiddenNavigationLink: some View {
        Group {
            if let id = navigateToTurnID {
                NavigationLink(value: id) { EmptyView() }
                    .opacity(0)
                    .onAppear {
                        DispatchQueue.main.async { navigateToTurnID = nil }
                    }
            }
        }
    }

    private func row(_ t: TurnEntity) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text(displayTitle(for: t))
                    .font(.headline)
                    .lineLimit(1)

                if t.isStarred {
                    Image(systemName: "star.fill")
                        .foregroundStyle(.yellow)
                        .imageScale(.small)
                        .accessibilityHidden(true)
                }

                Spacer()

                if let pill = statePillLabel(for: t.stateRaw) {
                    LaneBadge(text: pill)
                }
            }

            if let preview = transcriptPreview(for: t), !preview.isEmpty {
                Text(preview)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .textSelection(.enabled)
            }

            HStack(spacing: 8) {
                LaneBadge(text: contextLabel(captureContextRaw: t.captureContextRaw))
                Text(t.recordedAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }

    private func toggleStar(_ t: TurnEntity) {
        t.isStarred.toggle()
        try? modelContext.save()
    }

    private func delete(_ offsets: IndexSet) {
        let repo = TurnRepository(context: modelContext)
        let ids: [UUID] = offsets.compactMap { idx in
            guard turns.indices.contains(idx) else { return nil }
            return turns[idx].id
        }

        do {
            for id in ids {
                try repo.delete(id: id)
            }
        } catch {
            deleteErrorMessage = error.localizedDescription
            showDeleteError = true
        }
    }

    // MARK: - Title

    private func displayTitle(for t: TurnEntity) -> String {
        if !t.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return t.title
        }
        if let auto = autoTitleFromTranscript(for: t), !auto.isEmpty {
            return auto
        }
        return "Untitled"
    }

    private func autoTitleFromTranscript(for t: TurnEntity) -> String? {
        let source = transcriptPreview(for: t) ?? ""
        let cleaned = source
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\n", with: " ")

        guard !cleaned.isEmpty else { return nil }

        let words = cleaned.split(separator: " ").prefix(7).map(String.init)
        let title = words.joined(separator: " ")
        return String(title.prefix(56))
    }

    // MARK: - Labels

    private func contextLabel(captureContextRaw: String) -> String {
        switch captureContextRaw {
        case "carplay": return "Drive"
        case "handsfree": return "Hands-free"
        case "intent": return "Intent"
        case "handheld": return "Handheld"
        default: return "Local"
        }
    }

    private func statePillLabel(for stateRaw: String) -> String? {
        switch stateRaw {
        case "queued": return "Queued"
        case "recording": return "Recording"
        case "captured": return "Captured"
        case "transcribing", "transcribedRaw": return "Transcribing"
        case "redacting": return "Redacting"
        case "ready": return nil
        case "readyPartial": return "Partial"
        case "interrupted": return "Interrupted"
        case "failed": return "Failed"
        default: return "Processing"
        }
    }

    private func transcriptPreview(for t: TurnEntity) -> String? {
        if !t.transcriptRedactedActive.isEmpty { return t.transcriptRedactedActive }
        if let raw = t.transcriptRaw, !raw.isEmpty { return raw }
        return nil
    }
}
