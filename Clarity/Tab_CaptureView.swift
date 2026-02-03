// Tab_CaptureView.swift

import SwiftUI
import SwiftData
#if os(iOS)
import UIKit
#endif

struct Tab_CaptureView: View {
    @EnvironmentObject private var coordinator: TurnCaptureCoordinator
    @Environment(\.modelContext) private var modelContext

    @State private var showPermissionAlert: Bool = false
    @State private var permissionAlertTitleKey: String = "perm.title.generic"
    @State private var permissionAlertMessageKey: String = ""

    // Robust navigation path
    @State private var path: [UUID] = []

    // Sheet toggle for typing text
    @State private var showPasteSheet: Bool = false

    // MARK: - Turn count query (completed turns: has redacted text)
    @Query private var completedTurns: [TurnEntity]

    init() {
        _completedTurns = Query(
            filter: #Predicate<TurnEntity> { turn in
                !turn.transcriptRedactedActive.isEmpty
            },
            sort: [SortDescriptor(\TurnEntity.recordedAt, order: .reverse)]
        )
    }

    private enum Layout {
        static let vStackSpacing: CGFloat = 16          // was 18
        static let headerSpacing: CGFloat = 4           // was 6
        static let headerTopPadding: CGFloat = 4        // was 6

        static let micCoverSize: CGFloat = 120
        static let micDownSpacerMin: CGFloat = 12       // was 18
        static let belowStatusSpacerMin: CGFloat = 6    // was 8

        static let typeButtonVerticalPadding: CGFloat = 12
        static let errorTopPadding: CGFloat = 6

        static let statusDotSize: CGFloat = 6
        static let statusPillSpacing: CGFloat = 8
        static let statusPillHPadding: CGFloat = 12
        static let statusPillVPadding: CGFloat = 8
        static let statusAnimDuration: Double = 0.15

        static let chipsTopPadding: CGFloat = 4         // was 8
        static let chipsSpacing: CGFloat = 8            // was 10
        static let chipHPadding: CGFloat = 12           // was 14
        static let chipVPadding: CGFloat = 8            // was 10

        // Badge placement
        static let badgeTopPadding: CGFloat = 10
        static let badgeTrailingPadding: CGFloat = 14
    }

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                Color.clear.ignoresSafeArea()

                VStack(spacing: Layout.vStackSpacing) {
                    header

                    promptChips

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
            // Overlay badge so it doesn't affect layout
            .overlay(alignment: .topTrailing) {
                turnCountBadge(count: completedTurns.count)
                    .padding(.top, Layout.badgeTopPadding)
                    .padding(.trailing, Layout.badgeTrailingPadding)
                    .accessibilityLabel(Text("Completed turns: \(completedTurns.count)"))
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

    // MARK: - Header (kept centred)

    private var header: some View {
        VStack(spacing: Layout.headerSpacing) {
            Text(String(localized: "app.title"))
                .font(.title2.weight(.semibold))
                .multilineTextAlignment(.center)

            Text("Tap to speak or type a problem you want clarity on.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, Layout.headerTopPadding)
    }

    // MARK: - Prompt chips

    private var promptChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Layout.chipsSpacing) {
                chip("I can’t tell if…")
                chip("I’m stuck choosing…")
                chip("I feel tension with…")
            }
            .padding(.top, Layout.chipsTopPadding)
        }
    }

    private func chip(_ text: String) -> some View {
        Text(text)
            .font(.callout)
            .foregroundStyle(.secondary)
            .lineLimit(1)
            .padding(.horizontal, Layout.chipHPadding)
            .padding(.vertical, Layout.chipVPadding)
            .background(.thinMaterial)
            .clipShape(Capsule())
            .onTapGesture {
                showPasteSheet = true
            }
            .accessibilityLabel(Text(text))
    }

    // MARK: - Status pill

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

    // MARK: - Top-right badge (overlay; no layout impact)

    private func turnCountBadge(count: Int) -> some View {
        let shown = min(max(count, 0), 999)

        // Warmer yellow-gold (less green)
        let goldFill = Color(red: 0.96, green: 0.82, blue: 0.26)

        return Text("\(shown)")
            .font(.footnote.weight(.semibold))
            .foregroundStyle(.black)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(goldFill.opacity(0.90))
            .clipShape(Capsule())
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

