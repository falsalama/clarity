import SwiftUI
import SwiftData

/// Snapshot-only day detail.
/// No deep navigation. No branching. Just a compact record.
struct DayDetailView: View {
    let dayKey: String
    let label: String

    @Query private var reflectCompletions: [ReflectCompletionEntity]
    @Query private var focusCompletions: [FocusCompletionEntity]
    @Query private var practiceCompletions: [PracticeCompletionEntity]

    init(dayKey: String, label: String) {
        self.dayKey = dayKey
        self.label = label

        _reflectCompletions = Query(sort: [SortDescriptor(\ReflectCompletionEntity.completedAt, order: .reverse)])
        _focusCompletions = Query(sort: [SortDescriptor(\FocusCompletionEntity.completedAt, order: .reverse)])
        _practiceCompletions = Query(sort: [SortDescriptor(\PracticeCompletionEntity.completedAt, order: .reverse)])
    }

    private var didReflect: Bool { reflectCompletions.contains(where: { $0.dayKey == dayKey }) }
    private var didView: Bool { focusCompletions.contains(where: { $0.dayKey == dayKey }) }
    private var didPractice: Bool { practiceCompletions.contains(where: { $0.dayKey == dayKey }) }

    private var reflectTime: Date? { reflectCompletions.first(where: { $0.dayKey == dayKey })?.completedAt }
    private var viewTime: Date? { focusCompletions.first(where: { $0.dayKey == dayKey })?.completedAt }
    private var practiceTime: Date? { practiceCompletions.first(where: { $0.dayKey == dayKey })?.completedAt }
    private var reflectCompletion: ReflectCompletionEntity? {
        reflectCompletions.first(where: { $0.dayKey == dayKey })
    }

    private var viewCompletion: FocusCompletionEntity? {
        focusCompletions.first(where: { $0.dayKey == dayKey })
    }

    private var practiceCompletion: PracticeCompletionEntity? {
        practiceCompletions.first(where: { $0.dayKey == dayKey })
    }

    private var reflectPreview: String? { previewText(title: reflectCompletion?.title, body: reflectCompletion?.body) }
    private var viewPreview: String? { previewText(title: viewCompletion?.title, body: viewCompletion?.body) }
    private var practicePreview: String? { previewText(title: practiceCompletion?.title, body: practiceCompletion?.body) }

    private var completionSummary: String {
        let count = (didReflect ? 1 : 0) + (didView ? 1 : 0) + (didPractice ? 1 : 0)
        switch count {
        case 0: return "Not started"
        case 3: return "Complete"
        default: return "In progress (\(count)/3)"
            
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                headerCard
                sectionsCard
                noteCard
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 22)
        }
        .navigationTitle(label)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(label)
                    .font(.headline)
                Spacer()
                Text(dayKey)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 8) {
                statusDot(done: didReflect)
                statusDot(done: didView)
                statusDot(done: didPractice)
                Spacer()
                Text(completionSummary)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(.secondarySystemBackground)))
    }

    private var sectionsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Summary")
                .font(.headline)

            SectionRow(
                title: "Reflect",
                preview: reflectPreview,
                subtitle: didReflect ? (timeString(reflectTime) ?? "Completed") : "Not completed",
                isDone: didReflect,
                systemImage: "mic"
            )

            SectionRow(
                title: "View",
                preview: viewPreview,
                subtitle: didView ? (timeString(viewTime) ?? "Completed") : "Not completed",
                isDone: didView,
                systemImage: "book.closed"
            )

            SectionRow(
                title: "Practice",
                preview: practicePreview,
                subtitle: didPractice ? (timeString(practiceTime) ?? "Completed") : "Not completed",
                isDone: didPractice,
                systemImage: "leaf"
            )
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(.secondarySystemBackground)))
    }

    private var noteCard: some View {
        Text("This is a snapshot only.")
            .font(.footnote)
            .foregroundStyle(.secondary)
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 16).fill(Color(.secondarySystemBackground)))
    }

    private func statusDot(done: Bool) -> some View {
        Group {
            if done {
                Circle().fill(Color.primary.opacity(0.85))
            } else {
                Circle().strokeBorder(Color.secondary.opacity(0.4), lineWidth: 1.5)
            }
        }
        .frame(width: 10, height: 10)
        .accessibilityHidden(true)
    }

    private func timeString(_ date: Date?) -> String? {
        guard let date else { return nil }
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_GB")
        f.timeStyle = .short
        f.dateStyle = .none
        return f.string(from: date)
    }

    private func previewText(title: String?, body: String?) -> String? {
        // Prefer body for Reflect-like content (questions),
        // because title is often generic or empty.
        let b = (body ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        if !b.isEmpty {
            let oneLine = b
                .replacingOccurrences(of: "\n", with: " ")
                .replacingOccurrences(of: "  ", with: " ")
                .trimmingCharacters(in: .whitespacesAndNewlines)

            if oneLine.count <= 220 { return oneLine }
            return String(oneLine.prefix(217)) + "…"
        }

        let t = (title ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? nil : t
    }
}

private struct SectionRow: View {
    let title: String
    let preview: String?
    let subtitle: String
    let isDone: Bool
    let systemImage: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .frame(width: 22)

            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.subheadline.weight(.semibold))

                if let preview, !preview.isEmpty {
                    Text(preview)
                        .font(.footnote)
                        .foregroundStyle(.primary)
                        .lineLimit(4)
                }

                Text(subtitle)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: isDone ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemBackground)))
        .contentShape(Rectangle())
    }
}
