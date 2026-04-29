// PrivacyView.swift
import SwiftUI

struct PrivacyView: View {
    @EnvironmentObject private var supabaseAuth: SupabaseAuthStore

    @State private var showDeleteConfirmation = false
    @State private var isDeletingCloudAccount = false
    @State private var accountDeletionAlertTitle = ""
    @State private var accountDeletionAlertMessage: String?

    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Audio and raw transcripts stay on this device.")
                    Text("Cloud Tap sends only the selected redacted text when you choose a cloud response.")
                    Text("Health data is used on device for gentle pattern context. It is not sent to Cloud Tap.")
                }
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            }

            Section {
                LabeledContent("What can be sent") { Text("Redacted text only") }
                LabeledContent("Never sent") { Text("Audio, raw transcript, Health data") }
                LabeledContent("Per-call consent") { Text("Always required") }

                NavigationLink("View Send Preview") {
                    PayloadPreviewExplainerView()
                }
            } header: {
                Text("Data sharing")
            } footer: {
                Text("Preview exactly what would be sent for a specific action.")
            }

            Section {
                LabeledContent("Status") {
                    Text(cloudAccountStatus)
                        .foregroundStyle(.secondary)
                }

                Button(role: .destructive) {
                    showDeleteConfirmation = true
                } label: {
                    if isDeletingCloudAccount {
                        HStack(spacing: 8) {
                            ProgressView()
                            Text("Deleting Cloud Account…")
                        }
                    } else {
                        Text("Delete Cloud Account and Data")
                    }
                }
                .disabled(!canDeleteCloudAccount || isDeletingCloudAccount)
            } header: {
                Text("Cloud account")
            } footer: {
                Text("Deletes the anonymous Supabase account used for Cloud Tap entitlement and cloud access. Local reflections, audio, Health data, and on-device history remain on this iPhone. App Store subscriptions are still managed by Apple.")
            }

            Section {
                Text("Clarity supports reflection, practice, and Buddhist learning. It is not medical advice, therapy, diagnosis, treatment, or crisis support.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            } header: {
                Text("Scope")
            }
        }
        .navigationTitle("Privacy / Cloud Tap")
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
        .confirmationDialog(
            "Delete Cloud Account and Data?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete Cloud Account", role: .destructive) {
                deleteCloudAccount()
            }

            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This removes the current cloud account and server entitlement record. It does not delete local reflections or recordings from this iPhone. If you have an active subscription, cancel it from your App Store account settings.")
        }
        .alert(
            accountDeletionAlertTitle,
            isPresented: Binding(
                get: { accountDeletionAlertMessage != nil },
                set: { newValue in
                    if !newValue {
                        accountDeletionAlertMessage = nil
                        accountDeletionAlertTitle = ""
                    }
                }
            )
        ) {
            Button("OK", role: .cancel) {
                accountDeletionAlertMessage = nil
                accountDeletionAlertTitle = ""
            }
        } message: {
            Text(accountDeletionAlertMessage ?? "")
        }
    }

    private var canDeleteCloudAccount: Bool {
        if case .ready = supabaseAuth.state { return true }
        return false
    }

    private var cloudAccountStatus: String {
        switch supabaseAuth.state {
        case .ready(let userID):
            return "Active (\(userID.prefix(8))…)"
        case .signingIn:
            return "Preparing"
        case .idle:
            return "Not signed in"
        case .unavailable:
            return "Unavailable"
        case .failed:
            return "Unavailable"
        }
    }

    private func deleteCloudAccount() {
        guard !isDeletingCloudAccount else { return }
        isDeletingCloudAccount = true

        Task {
            do {
                try await supabaseAuth.deleteCloudAccountAndData()
                accountDeletionAlertTitle = "Cloud Account Deleted"
                accountDeletionAlertMessage = "The current cloud account and server entitlement record were deleted. A new anonymous cloud account will be created if Cloud Tap is used again."
            } catch {
                accountDeletionAlertTitle = "Couldn’t Delete Cloud Account"
                accountDeletionAlertMessage = error.localizedDescription
            }

            isDeletingCloudAccount = false
        }
    }
}

private struct PayloadPreviewExplainerView: View {
    var body: some View {
        List {
            Section {
                Text("Preview what would be sent when you choose Cloud Tap for an action. Includes redacted text, timing, and limited context.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section("Included") {
                Text("Redacted transcript")
                Text("Timestamp")
                Text("Capture context (minimal)")
                Text("Capsule summary (bounded)")
            }

            Section("Excluded") {
                Text("Audio files")
                Text("Raw transcript")
                Text("Health data")
            }
        }
        .navigationTitle("Send Preview")
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
    }
}

#Preview {
    NavigationStack {
        PrivacyView()
            .environmentObject(SupabaseAuthStore())
    }
}
