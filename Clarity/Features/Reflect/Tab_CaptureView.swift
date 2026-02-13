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

    // Completed turns count (badge)
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
        static let headerTopPadding: CGFloat = 4

        static let micSize: CGFloat = 128
        static let micStrokeOpacity: Double = 0.22

        static let statusPillSpacing: CGFloat = 8
        static let statusPillHPadding: CGFloat = 12
        static let statusPillVPadding: CGFloat = 8
        static let statusAnimDuration: Double = 0.15

        static let chipsTopPadding: CGFloat = 6
        static let chipsSpacing: CGFloat = 8
        static let chipHPadding: CGFloat = 12
        static let chipVPadding: CGFloat = 8

        static let badgeTopPadding: CGFloat = 4
        static let badgeTrailingPadding: CGFloat = 4

        static let sectionCorner: CGFloat = 16
    }

    var body: some View {
        NavigationStack(path: $path) {
            List {
                captureSurfaceSection
                capturesSection
            }
            .listStyle(.plain)
            .navigationTitle("Reflect")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        ProgressScreen()
                    } label: {
                        // Reflect tab badge: soft white (not gold).
                        TopCounterBadge(
                            count: min(108, completedTurns.count),
                            fill: Color.white.opacity(0.92),
                            textColor: .black
                        )
                        .overlay(
                            Capsule().stroke(.black.opacity(0.08), lineWidth: 1)
                        )
                    }
                    .accessibilityLabel(Text("Progress: \(min(108, completedTurns.count)) of 108"))
                }
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
                Button(String(localized: "perm.button.cancel"), role: .cancel) {}
            } message: {
                Text(LocalizedStringKey(permissionAlertMessageKey))
            }
            .sheet(isPresented: $showPasteSheet) {
                PasteTextTurnSheet { newID in
                    path.append(newID)
                }
                .environmentObject(coordinator)
            }
        }
    }

    // MARK: - Sections

    private var captureSurfaceSection: some View {
        Section {
            VStack(spacing: 12) {
                promptChips
                micButton
                statusPill
                    .animation(.easeInOut(duration: Layout.statusAnimDuration), value: coordinator.phase)
                typeTextButton

                if let uiErrorKey = userFacingErrorKey {
                    Text(LocalizedStringKey(uiErrorKey))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.top, 4)
                }
            }
            .padding(.vertical, 6)
            .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))
            .listRowSeparator(.hidden)
        } header: {
            EmptyView()
        }
    }

    private var capturesSection: some View {
        Section {
            let items: [TurnEntity] = Array(completedTurns.prefix(25))
            if items.isEmpty {
                Text("Nothing here yet.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .listRowSeparator(.hidden)
            } else {
                ForEach(items) { t in
                    NavigationLink(value: t.id) {
                        captureRow(t)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            deleteTurn(t)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }

                        Button {
                            starTurn(t)
                        } label: {
                            Label(t.isStarred ? "Unstar" : "Star",
                                  systemImage: t.isStarred ? "star.slash" : "star")
                        }
                        .tint(.yellow)
                    }
                    .listRowSeparator(.visible)
                    .listRowSeparatorTint(.secondary.opacity(0.45))
                }
            }
        } header: {
            HStack {
                Text("Captures")
                Spacer()
                Text("\(completedTurns.count)")
                    .foregroundStyle(.secondary)
            }
            .font(.headline)
            .textCase(nil)
        }
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
            .onTapGesture { showPasteSheet = true }
            .accessibilityAddTraits(.isButton)
    }

    // MARK: - Mic button (primary)

    private var micButton: some View {
        CaptureButton(
            phase: coordinator.phase,
            isEnabled: micButtonEnabled,
            level: coordinator.level
        ) {
            switch coordinator.phase {
            case .idle:
                coordinator.startCapture()
            case .recording:
                coordinator.stopCapture()
            default:
                break
            }
        }
        .padding(.top, 4)
    }

    private var micButtonEnabled: Bool {
        coordinator.phase == .idle || coordinator.phase == .recording
    }

    // MARK: - Status

    private var statusPill: some View {
        HStack(spacing: Layout.statusPillSpacing) {
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
        .padding(.horizontal, Layout.statusPillHPadding)
        .padding(.vertical, Layout.statusPillVPadding)
        .background(.thinMaterial)
        .clipShape(Capsule())
    }

    private var statusTextKey: String {
        switch coordinator.phase {
        case .idle: return "capture.ready"
        case .preparing: return "capture.preparing"
        case .recording: return "capture.listening"
        case .finalising, .transcribing, .redacting: return "capture.processing"
        }
    }

    // MARK: - Type text

    private var typeTextButton: some View {
        Button { showPasteSheet = true } label: {
            Text("Type text")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8) // less padding (requested)
        }
        .buttonStyle(.bordered)
        .disabled(coordinator.phase != .idle)
        .accessibilityLabel(Text("Type text"))
    }

    // MARK: - Capture row

    private func captureRow(_ t: TurnEntity) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Text(title(for: t))
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)

                if t.isStarred {
                    Image(systemName: "star.fill")
                        .foregroundStyle(.yellow)
                        .imageScale(.small)
                        .accessibilityHidden(true)
                }
            }

            let preview = t.transcriptRedactedActive.trimmingCharacters(in: .whitespacesAndNewlines)
            if !preview.isEmpty {
                Text(preview)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .contentShape(Rectangle())
        .padding(.vertical, 2)
    }

    private func title(for t: TurnEntity) -> String {
        let v = t.title.trimmingCharacters(in: .whitespacesAndNewlines)
        return v.isEmpty ? "Capture" : v
    }

    // MARK: - Swipe actions

    private func deleteTurn(_ t: TurnEntity) {
        modelContext.delete(t)
        do { try modelContext.save() } catch { /* keep silent for now */ }
    }

    private func starTurn(_ t: TurnEntity) {
        t.isStarred.toggle()
        do { try modelContext.save() } catch { /* best-effort */ }
    }

    // MARK: - Errors

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
