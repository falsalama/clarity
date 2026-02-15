import SwiftUI
import SwiftData

/// ReflectCapturesInlineList
/// - Inline list intended to sit underneath the capture UI on the Reflect tab.
/// - No NavigationStack. Uses NavigationLink(value:) so parent controls destination.
/// - Keeps it light: latest N items, plus a count header.
struct ReflectCapturesInlineList: View {
    @Query(sort: \TurnEntity.recordedAt, order: .reverse) private var turns: [TurnEntity]

    // Keep it fast and visually tidy
    private let maxShown: Int = 10

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Captures")
                    .font(.headline)
                Spacer()
                Text("\(turns.count)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            if turns.isEmpty {
                Text("Nothing here yet.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 6)
            } else {
                VStack(spacing: 8) {
                    ForEach(Array(turns.prefix(maxShown))) { t in
                        NavigationLink(value: t.id) {
                            row(t)
                        }
                        .buttonStyle(.plain)

                        Divider().opacity(0.25)
                    }
                }
                .padding(.top, 2)
            }
        }
        .padding()
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func row(_ t: TurnEntity) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title(for: t))
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)

            let preview = t.transcriptRedactedActive.trimmingCharacters(in: .whitespacesAndNewlines)
            if !preview.isEmpty {
                Text(preview)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .contentShape(Rectangle())
    }

    private func title(for t: TurnEntity) -> String {
        let v = t.title.trimmingCharacters(in: .whitespacesAndNewlines)
        return v.isEmpty ? "Capture" : v
    }
}

