import SwiftUI
import UniformTypeIdentifiers

struct SettingsSectionView: View {
    @EnvironmentObject private var cloudTap: CloudTapSettings
    @EnvironmentObject private var redactionDictionary: RedactionDictionary

    // Local model manager (singleton)
    @ObservedObject private var localModel = LocalModelManager.shared

    @State private var newToken: String = ""
    @FocusState private var tokenFieldFocused: Bool

    // File import for .gguf
    @State private var showImporter: Bool = false
    @State private var importError: String? = nil

    var body: some View {
        Form {
            Section(header: Text("Cloud Tap")) {
                Toggle("Enable Cloud Tap", isOn: $cloudTap.isEnabled)
                Toggle("Show lane badges", isOn: $cloudTap.showLaneBadges)
            }

            Section {
                Text("Redaction replaces matching words or phrases in transcripts to protect privacy.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            // On-device model management
            Section(
                header: Text("On-device model"),
                footer: Text("The model is stored in Application Support/models. Import lets you add a .gguf you’ve placed via Files.")
            ) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(localModel.modelNameForUI)
                        .font(.headline)

                    Text(statusText)
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    if localModel.existsForUI {
                        Text("File: \(localModel.expectedFileNameForUI)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        if localModel.fileSizeBytesForUI > 0 {
                            Text("Size: \(formatBytes(localModel.fileSizeBytesForUI))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        Text("Expected file: \(localModel.expectedFileNameForUI)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                if case .downloading(let p) = localModel.state {
                    if let p = p {
                        ProgressView(value: p)
                    } else {
                        ProgressView()
                    }
                }

                HStack {
                    switch localModel.state {
                    case .notInstalled, .failed:
                        Button("Download model") { localModel.startDownload() }
                        Button("Import .gguf…") { showImporter = true }

                    case .downloading:
                        Button("Cancel download") { localModel.cancelDownload() }
                            .tint(.orange)

                    case .ready:
                        Button("Delete model", role: .destructive) { localModel.deleteModel() }
                        Button("Re-download") {
                            localModel.deleteModel()
                            localModel.startDownload()
                        }
                    }
                }
            }

            Section(header: Text("Redaction dictionary")) {
                if redactionDictionary.tokens.isEmpty {
                    Text("No redaction tokens yet.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(redactionDictionary.tokens, id: \.self) { token in
                        Text(token)
                            .textSelection(.enabled)
                    }
                    .onDelete { offsets in
                        redactionDictionary.remove(at: offsets)
                    }
                }

                HStack {
                    TextField("Add word or phrase", text: $newToken)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                        .submitLabel(.done)
                        .focused($tokenFieldFocused)
                        .onSubmit { addToken() }

                    Button("Add") { addToken() }
                        .disabled(newToken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }

            Section {
                Button(role: .destructive) {
                    redactionDictionary.wipe()
                } label: {
                    Text("Clear redaction dictionary")
                }
            }

            Section(header: Text("About")) {
                HStack {
                    Text("Version")
                    Spacer()
                    Text(appVersion)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Settings")
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
        .onAppear { localModel.refreshStatePublic() }
        .fileImporter(
            isPresented: $showImporter,
            allowedContentTypes: [UTType(filenameExtension: "gguf") ?? .data],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    do {
                        try localModel.importModel(from: url)
                    } catch {
                        importError = error.localizedDescription
                    }
                }
            case .failure(let error):
                importError = error.localizedDescription
            }
        }
        .alert("Import failed", isPresented: Binding(
            get: { importError != nil },
            set: { if !$0 { importError = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(importError ?? "")
        }
    }

    private var appVersion: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
        return "\(v) (\(b))"
    }

    private var statusText: String {
        switch localModel.state {
        case .notInstalled:
            return "Not installed."
        case .downloading(let p):
            if let p = p { return "Downloading… \(Int(p * 100))%" }
            return "Downloading…"
        case .ready:
            return "Installed and ready."
        case .failed(let msg):
            return "Failed: \(msg)"
        }
    }

    private func addToken() {
        let t = newToken.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return }
        redactionDictionary.add(t)
        newToken = ""
        tokenFieldFocused = false
    }

    private func formatBytes(_ n: Int64) -> String {
        let mb = Double(n) / (1024.0 * 1024.0)
        if mb >= 1024 { return String(format: "%.1f GB", mb / 1024.0) }
        return String(format: "%.0f MB", mb)
    }
}

#Preview {
    NavigationStack {
        SettingsSectionView()
            .environmentObject(CloudTapSettings())
            .environmentObject(RedactionDictionary())
    }
}
