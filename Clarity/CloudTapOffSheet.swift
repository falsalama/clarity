import SwiftUI

struct CloudTapOffSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Cloud Tap is disabled")
                        .font(.headline)
                    Text("Enable Cloud Tap to run Reflect, perspective, Options, Questions, or Talk it through. You always confirm each send, and only redacted text is shared.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                NavigationLink {
                    PrivacyView()
                } label: {
                    Text("Open Privacy / Cloud Tap")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                Button("Close") { dismiss() }
                    .buttonStyle(.bordered)
            }
            .padding()
            .navigationTitle("Cloud Tap Off")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    CloudTapOffSheet()
}
