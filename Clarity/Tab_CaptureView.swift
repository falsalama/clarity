import SwiftUI
#if os(iOS)
import UIKit
#endif

struct Tab_CaptureView: View {
    @EnvironmentObject private var coordinator: TurnCaptureCoordinator

    @State private var showPermissionAlert: Bool = false
    @State private var permissionAlertTitleKey: String = "perm.title.generic"
    @State private var permissionAlertMessageKey: String = ""

    @State private var path: [UUID] = []
    @State private var showPasteSheet: Bool = false

    private enum Layout {
        static let vStackSpacing: CGFloat = 18
        static let headerSpacing: CGFloat = 6
        static let headerTopPadding: CGFloat = 6
        static let micCoverSize: CGFloat = 120
        static let micDownSpacerMin: CGFloat = 18
        static let belowStatusSpacerMin: CGFloat = 8
        static let typeButtonVerticalPadding: CGFloat = 12
        static let errorTopPadding: CGFloat = 6
        static let statusDotSize: CGFloat = 6
        static let statusPillSpacing: CGFloat = 8
        static let statusPillHPadding: CGFloat = 12
        static let statusPillVPadding: CGFloat = 8
        static let statusAnimDuration: Double = 0.15
    }

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                Color.clear.ignoresSafeArea()

                VStack(spacing: Layout.vStackSpacing) {
                    header

                    Spacer(minLength: Layout.micDownSpacerMin)

                    ZStack {
                        Circle()
                            .fill(Color(.systemBackground))
                            .frame(width: Layout.micCoverSize, height: Layout.micCoverSize)

                        CaptureButton(
                            phase: coordinator.phase,
                            isEnabled: !primaryButtonDisabled,
                            level: coordinator.level,
                            action: coordinator.toggleCapture
                        )
                    }

                    // Status pill without layout shift
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
                    .animation(.easeInOut(duration: Layout.statusAnimDuration), value: coordinator.phase)

                    Spacer(minLength: Layout.belowStatusSpacerMin)

                    Button {
                        showPasteSheet = true
                    } label: {
                        Text("capture.type_text")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Layout.typeButtonVerticalPadding)
                            .background(Color(red: 0.08, green: 0.24, blue: 0.60))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Text("capture.type_text.a11y.label"))
                    .accessibilityHint(Text("capture.type_text.a11y.hint"))

                    if let uiErrorKey = userFacingErrorKey {
                        Text(LocalizedStringKey(uiErrorKey))
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .padding(.top, Layout.errorTopPadding)
                            .multilineTextAlignment(.center)
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
            .onChange(of: coordinator.uiError) { _, newValue in
                guard let err = newValue else { return }

                switch err {
                case .micDenied, .micNotGranted:
                    permissionAlertTitleKey = "perm.mic.title"
                    permissionAlertMessageKey = "perm.mic.message"
                    showPermissionAlert = true

                case .speechDeniedOrNotAuthorised, .speechUnavailable:
                    permissionAlertTitleKey = "perm.speech.title"
                    permissionAlertMessageKey = "perm.speech.message"
                    showPermissionAlert = true

                default:
                    break
                }
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

    private var header: some View {
        VStack(spacing: Layout.headerSpacing) {
            Text(String(localized: "app.title"))
                .font(.title2.weight(.semibold))
            Text(String(localized: "capture.tagline"))
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .padding(.top, Layout.headerTopPadding)
    }

    private var statusPill: some View {
        HStack(spacing: Layout.statusPillSpacing) {
            Text(LocalizedStringKey(statusTextKey))
                .font(.footnote)
                .foregroundStyle(.secondary)

            if coordinator.phase == .recording {
                Circle()
                    .frame(width: Layout.statusDotSize, height: Layout.statusDotSize)
                    .foregroundStyle(.secondary)
                    .opacity(0.85)
            }
        }
        .padding(.horizontal, Layout.statusPillHPadding)
        .padding(.vertical, Layout.statusPillVPadding)
        .background(.thinMaterial)
        .clipShape(Capsule())
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
        default:
            return true
        }
    }

    private var userFacingErrorKey: String? {
        guard let err = coordinator.uiError else { return nil }

        switch err {
        case .notReady:
            return "error.capture.not_ready"
        case .couldntStartCapture:
            return "error.capture.start_failed"
        case .couldntSaveTranscript:
            return "error.capture.save_failed"
        case .noTranscriptCaptured:
            return "error.capture.no_speech"
        default:
            return nil
        }
    }

    private func openAppSettings() {
#if os(iOS)
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
#endif
    }
}

#Preview {
    Tab_CaptureView()
        .environmentObject(TurnCaptureCoordinator())
}
