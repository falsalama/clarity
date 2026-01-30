// Tab_CaptureView.swift
import SwiftUI
#if os(iOS)
import UIKit
#endif

struct Tab_CaptureView: View {
    @EnvironmentObject private var coordinator: TurnCaptureCoordinator

    @State private var showPermissionAlert: Bool = false
    @State private var permissionAlertTitleKey: String = "perm.title.generic"
    @State private var permissionAlertMessageKey: String = ""

    // Robust navigation path
    @State private var path: [UUID] = []

    // Sheet toggle for typing text
    @State private var showPasteSheet: Bool = false

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                Image("CaptureBackground")
                    .resizable()
                    .scaledToFill()
                    .scaleEffect(0.57)          // tweak
                    .offset(x: -48, y: -6)       // tweak (negative moves up)
                    .ignoresSafeArea()
                    .clipped()
                    .accessibilityHidden(true)
                    .opacity(0.35) // try 0.25–0.45

                VStack(spacing: 18) {
                    header

                    // NEW: extra space to push mic button down slightly
                    Spacer(minLength: 18)

                    ZStack {
                        // Covers the mic icon baked into the background image.
                        // Uses dynamic system background so it matches Light/Dark mode.
                        Circle()
                            .fill(Color(.systemBackground))
                            .frame(width: 120, height: 120)

                        CaptureButton(
                            phase: coordinator.phase,
                            isEnabled: !primaryButtonDisabled,
                            level: coordinator.level,
                            action: coordinator.toggleCapture
                        )
                    }

                    // Keep sizes stable: show status pill without affecting layout
                    // (presents for non-idle states, but doesn’t push the mic button around)
                    ZStack {
                        if coordinator.phase != .idle {
                            statusPill
                                .transition(.opacity)
                        }
                    }
                    .frame(height: 0)
                    .overlay {
                        if coordinator.phase != .idle {
                            statusPill
                        }
                    }
                    .animation(.easeInOut(duration: 0.15), value: coordinator.phase)

                    Spacer(minLength: 8)

                    Button {
                        showPasteSheet = true
                    } label: {
                        Text("Type text")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color(red: 0.08, green: 0.24, blue: 0.60))
                            .clipShape(SwiftUI.Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Type text")

                    if let e = coordinator.lastError, !e.isEmpty {
                        Text(e)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .padding(.top, 6)
                    }
                }
                .padding()
            }
            .navigationDestination(for: UUID.self) { id in
                TurnDetailView(turnID: id)
            }
            .onChange(of: coordinator.lastCompletedTurnID) { _, newValue in
                guard let id = newValue else { return }
                guard coordinator.isCarPlayConnected == false else { return }

                coordinator.clearLiveTranscript()
                path.append(id)
                coordinator.lastCompletedTurnID = nil
            }
            .onChange(of: coordinator.lastError) { _, newValue in
                guard let msg = newValue, !msg.isEmpty else { return }
                guard let denial = PermissionDenialDetection.from(errorMessage: msg) else { return }

                permissionAlertTitleKey = denial.titleKey
                permissionAlertMessageKey = denial.messageKey
                showPermissionAlert = true
            }
            .alert(
                Text(LocalizedStringKey(permissionAlertTitleKey)),
                isPresented: $showPermissionAlert
            ) {
                Button(String(localized: "perm.button.open_settings")) { openAppSettings() }
                Button(String(localized: "perm.button.ok"), role: .cancel) {}
            } message: {
                Text(LocalizedStringKey(permissionAlertMessageKey))
            }
            .sheet(isPresented: $showPasteSheet) {
                PasteTextTurnSheet { newID in
                    path.append(newID)
                }
            }
        }
    }

    // MARK: - UI

    private var header: some View {
        VStack(spacing: 6) {
            Text(String(localized: "app.title"))
                .font(.title2.weight(.semibold))
            Text(String(localized: "capture.tagline"))
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 6)
    }

    private var statusPill: some View {
        HStack(spacing: 8) {
            Text(LocalizedStringKey(statusTextKey))
                .font(.footnote)
                .foregroundStyle(.secondary)

            if coordinator.phase == .recording {
                Circle()
                    .frame(width: 6, height: 6)
                    .foregroundStyle(.secondary)
                    .opacity(0.85)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.thinMaterial)
        .clipShape(SwiftUI.Capsule())
    }

    private var statusTextKey: String {
        switch coordinator.phase {
        case .idle: return "capture.ready"
        case .recording: return "capture.listening"
        case .finalising: return "capture.saving"
        case .transcribing: return "capture.transcribing"
        case .redacting: return "capture.redacting"
        }
    }

    private var primaryButtonDisabled: Bool {
        switch coordinator.phase {
        case .idle, .recording:
            return false
        case .finalising, .transcribing, .redacting:
            return true
        }
    }

    private func openAppSettings() {
#if os(iOS)
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
#endif
    }
}

// MARK: - Local permission detection

private enum PermissionDenialDetection {
    struct Denial {
        let titleKey: String
        let messageKey: String
    }

    static func from(errorMessage: String) -> Denial? {
        let msg = errorMessage.lowercased()

        if msg.contains("microphone permission denied") || msg.contains("microphone permission not granted") {
            return Denial(titleKey: "perm.mic.title", messageKey: "perm.mic.message")
        }

        if msg.contains("speech not authorised")
            || msg.contains("speech not authorized")
            || msg.contains("speech recogniser unavailable")
            || msg.contains("speech recognizer unavailable") {
            return Denial(titleKey: "perm.speech.title", messageKey: "perm.speech.message")
        }

        return nil
    }
}

#Preview {
    Tab_CaptureView()
        .environmentObject(TurnCaptureCoordinator())
}

