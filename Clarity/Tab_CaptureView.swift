// Tab_CaptureView.swift
import SwiftUI
#if os(iOS)
import UIKit
#endif

struct Tab_CaptureView: View {
    @EnvironmentObject private var coordinator: TurnCaptureCoordinator

    @State private var showTranscript: Bool = true
    @State private var showExpandedTranscript: Bool = false

    @State private var showPermissionAlert: Bool = false
    @State private var permissionAlertTitleKey: String = "perm.title.generic"
    @State private var permissionAlertMessageKey: String = ""

    var body: some View {
        VStack(spacing: 18) {
            header

            CaptureButton(
                phase: coordinator.phase,
                isEnabled: !primaryButtonDisabled,
                level: coordinator.level,
                action: coordinator.toggleCapture
            )
            .padding(.top, 10)

            statusPill
            transcriptCard

            if let e = coordinator.lastError, !e.isEmpty {
                Text(e)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.top, 6)
            }

            Spacer(minLength: 0)
        }
        .padding()
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

    @ViewBuilder
    private var transcriptCard: some View {
        let text = coordinator.liveTranscript.trimmingCharacters(in: .whitespacesAndNewlines)
        if !text.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(String(localized: "capture.transcript"))
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    Spacer()

                    Text(String(localized: coordinator.phase == .recording ? "capture.transcript.raw_live" : "capture.transcript.last_capture"))
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    Button(String(localized: "capture.transcript.expand")) { showExpandedTranscript = true }
                        .font(.footnote.weight(.medium))

                    Button(String(localized: showTranscript ? "capture.transcript.hide" : "capture.transcript.show")) { showTranscript.toggle() }
                        .font(.footnote.weight(.medium))
                }

                if showTranscript {
                    ScrollView {
                        Text(coordinator.liveTranscript)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .textSelection(.enabled)
                            .font(.body)
                    }
                    .frame(maxHeight: 260)
                }
            }
            .padding(14)
            .background(.thinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .padding(.top, 8)
            .sheet(isPresented: $showExpandedTranscript) {
                ExpandedTranscriptView(
                    title: String(localized: "capture.transcript"),
                    text: coordinator.liveTranscript
                )
            }
        }
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

// MARK: - Local UI

private struct CaptureButton: View {
    let phase: TurnCaptureCoordinator.Phase
    let isEnabled: Bool
    let level: Double
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(.thinMaterial)

                    if phase == .recording {
                        Circle()
                            .strokeBorder(.tint, lineWidth: 2)
                            .scaleEffect(1.02 + (0.18 * level))
                            .opacity(0.12 + (0.18 * level))
                            .animation(.easeOut(duration: 0.10), value: level)
                    }

                    if phase == .recording {
                        Image(systemName: "stop.circle.fill")
                            .font(.system(size: 40, weight: .semibold))
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(.tint)
                    } else {

                        Image(systemName: "mic.fill")
                            .font(.system(size: 30, weight: .semibold))
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(.primary)
                    }
                }
                .frame(width: 132, height: 132)
                .contentShape(Circle())

                if phase == .recording {
                    Text(String(localized: "capture.tap_to_stop"))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1.0 : 0.55)
        .tint(phase == .recording ? .red : .primary)
        .accessibilityLabel(String(localized: phase == .recording ? "capture.a11y.stop" : "capture.a11y.start"))
    }
}

private struct ExpandedTranscriptView: View {
    let title: String
    let text: String

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                Text(text)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
                    .padding()
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(String(localized: "perm.button.ok")) { dismiss() }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        Tab_CaptureView()
            .environmentObject(TurnCaptureCoordinator())
    }
}

