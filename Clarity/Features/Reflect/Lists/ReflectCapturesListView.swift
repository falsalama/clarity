import SwiftUI
import SwiftData

/// ReflectCapturesListView
/// - Captures list that lives inside Reflect.
/// - Does NOT own a NavigationStack (it is pushed from Reflect’s NavigationStack).
struct ReflectCapturesListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TurnEntity.recordedAt, order: .reverse) private var turns: [TurnEntity]

    @State private var deleteErrorMessage: String?
    @State private var showDeleteError: Bool = false

    var body: some View {
        List {
            if turns.isEmpty {
                ContentUnavailableView("No captures yet", systemImage: "mic")
            } else {
                ForEach(turns) { t in
                    NavigationLink(value: t.id) {
                        row(t)
                    }
                }
                .onDelete(perform: delete)
            }
        }
        .navigationTitle("Captures")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Couldn’t delete capture", isPresented: $showDeleteError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(deleteErrorMessage ?? "Please try again.")
        }
    }

    private func row(_ t: TurnEntity) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text(displayTitle(for: t))
                    .font(.headline)
                    .lineLimit(1)

                Spacer()

                if let pill = statePillLabel(for: t.stateRaw) {
                    LaneBadge(text: pill)
                }
            }

            let preview = t.transcriptRedactedActive.trimmingCharacters(in: .whitespacesAndNewlines)
            if !preview.isEmpty {
                Text(preview)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .textSelection(.enabled)
            }

            HStack(spacing: 8) {
                LaneBadge(text: contextLabel(t.captureContextRaw))
                Text(Self.shortDateTime.string(from: t.recordedAt))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }

    private func displayTitle(for t: TurnEntity) -> String {
        let title = t.title.trimmingCharacters(in: .whitespacesAndNewlines)
        return title.isEmpty ? "Capture" : title
    }

    private func contextLabel(_ raw: String) -> String {
        let v = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if v.isEmpty || v == "unknown" { return "Reflect" }
        return v.capitalized
    }

    private func statePillLabel(for raw: String) -> String? {
        switch raw {
        case "queued": return "Queued"
        case "recording": return "Recording"
        case "captured": return "Captured"
        case "transcribing": return "Transcribing"
        case "transcribedRaw": return "Transcribed"
        case "redacting": return "Redacting"
        case "ready": return "Ready"
        case "readyPartial": return "Partial"
        case "interrupted": return "Interrupted"
        case "failed": return "Failed"
        default: return nil
        }
    }

    private func delete(at offsets: IndexSet) {
        do {
            for index in offsets {
                modelContext.delete(turns[index])
            }
            try modelContext.save()
        } catch {
            deleteErrorMessage = error.localizedDescription
            showDeleteError = true
        }
    }

    private static let shortDateTime: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }()
}

