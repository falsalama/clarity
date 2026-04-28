// AppShellView.swift

import SwiftUI
import SwiftData
import UIKit

struct AppShellView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase

    // Injected from ClarityApp.swift
    @EnvironmentObject private var cloudTap: CloudTapSettings
    @EnvironmentObject private var providerSettings: ContemplationProviderSettings
    @EnvironmentObject private var capsuleStore: CapsuleStore
    @EnvironmentObject private var redactionDictionary: RedactionDictionary
    @EnvironmentObject private var homeSurface: HomeSurfaceStore
    @EnvironmentObject private var supabaseAuth: SupabaseAuthStore
    @EnvironmentObject private var nowPlaying: NowPlayingStore

    // Owned here
    @StateObject private var captureCoordinator = TurnCaptureCoordinator()
    @StateObject private var flow = AppFlowRouter()

    @State private var didBind = false
    @State private var pendingSiriStart = false
    @State private var siriTask: Task<Void, Never>? = nil
    @State private var didBootstrapSupabaseAuth = false

    init() {
        // Ensure the tab bar is opaque and styled from the very first frame.
        Self.configureGlobalTabBarAppearance()
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .bottom) {
                TabView(selection: tabSelection) {

                    NavigationStack { HomeView() }
                        .id(flow.homeNavigationResetSeed)
                        .tabItem { Label("Home", systemImage: "house") }
                        .tag(AppFlowRouter.Tab.home)

                    NavigationStack {
                        CaptureView(
                            autoPopOnDone: false,
                            hideDailyQuestion: true,
                            embedInNavigationStack: false
                        )
                    }
                    .tabItem { Label("Reflect", systemImage: "mic") }
                    .tag(AppFlowRouter.Tab.reflect)

                    NavigationStack { MeditationZoneView() }
                        .tabItem {
                            VStack(spacing: 0) {
                                Image("meditate")
                                    .renderingMode(.template)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 24, height: 24)

                                Text("Meditation")
                                    .offset(y: 4)
                            }
                        }
                        .tag(AppFlowRouter.Tab.meditation)

                    NavigationStack { ExploreView() }
                        .tabItem { Label("Explore", systemImage: "square.grid.2x2") }
                        .tag(AppFlowRouter.Tab.explore)

                    NavigationStack { ProfileHubView() }
                        .tabItem { Label("Profile", systemImage: "person.crop.circle") }
                        .tag(AppFlowRouter.Tab.profile)
                }

                if nowPlaying.showsMiniPlayer {
                    NowPlayingMiniBar()
                        .environmentObject(nowPlaying)
                        .padding(.horizontal, 12)
                        .padding(.bottom, 56 + max(proxy.safeAreaInsets.bottom * 0.3, 0))
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .zIndex(20)
                } else if nowPlaying.showsCompactPlayer {
                    HStack {
                        Spacer()

                        CompactNowPlayingButton()
                            .environmentObject(nowPlaying)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 56 + max(proxy.safeAreaInsets.bottom * 0.3, 0))
                    .transition(.scale(scale: 0.92).combined(with: .opacity))
                    .zIndex(20)
                }
            }
        }
        .environmentObject(flow)
        .environmentObject(captureCoordinator)
        .environmentObject(homeSurface)
        .animation(.spring(response: 0.28, dampingFraction: 0.92), value: nowPlaying.chromeStateToken)
        .sheet(isPresented: $nowPlaying.isExpanded) {
            ExpandedNowPlayingView()
                .environmentObject(nowPlaying)
        }
        .onAppear {
            guard !didBind else { return }
            didBind = true
            
            if !didBootstrapSupabaseAuth {
                didBootstrapSupabaseAuth = true
                Task {
#if DEBUG
                    print("Supabase bootstrap from AppShellView starting")
#endif
                    await supabaseAuth.bootstrapAnonymousSessionIfNeeded()
#if DEBUG
                    print("Supabase bootstrap from AppShellView finished")
#endif
                }
            }
            
            try? WisdomSeed.seedIfNeeded(in: modelContext)

            captureCoordinator.bind(
                modelContext: modelContext,
                dictionary: redactionDictionary,
                capsuleStore: capsuleStore
            )

            LearningSync.sync(context: modelContext, capsuleStore: capsuleStore)

            if SiriLaunchFlag.consumeStartCaptureRequest() {
                pendingSiriStart = true
                flow.selectedTab = .reflect
            }

            if scenePhase == .active {
                scheduleSiriStartIfNeeded()
            }

            homeSurface.startDailyAutoRefresh()
            Task { await homeSurface.refreshNow() }
            
            Task {
                await NotificationManager.shared.refreshDailyScheduleIfEnabled()
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            captureCoordinator.handleScenePhaseChange(newPhase)

            if newPhase == .active {
                LearningSync.sync(context: modelContext, capsuleStore: capsuleStore)

                if SiriLaunchFlag.consumeStartCaptureRequest() {
                    pendingSiriStart = true
                    flow.selectedTab = .reflect
                }

                scheduleSiriStartIfNeeded()

                homeSurface.startDailyAutoRefresh()
                Task { await homeSurface.refreshNow() }

                Task {
                    await NotificationManager.shared.refreshDailyScheduleIfEnabled()
                }

            } else {
                siriTask?.cancel()
                siriTask = nil
                homeSurface.stopDailyAutoRefresh()
            }
        }
    }

    private var tabSelection: Binding<AppFlowRouter.Tab> {
        Binding(
            get: { flow.selectedTab },
            set: { newValue in
                switch newValue {
                case .home:
                    flow.openPracticeHomeAtRoot()
                default:
                    flow.selectedTab = newValue
                }
            }
        )
    }
    // MARK: - Fixed tab bar appearance

    private static func configureGlobalTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithTransparentBackground()

        // Let the content behind influence the feel again (like before).
        appearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterial)
        appearance.backgroundColor = .clear
        appearance.shadowColor = UIColor.black.withAlphaComponent(0.10)

        UITabBar.appearance().standardAppearance = appearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }

    // MARK: - Siri start handling

    private func scheduleSiriStartIfNeeded() {
        guard pendingSiriStart else { return }

        siriTask?.cancel()
        siriTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_200_000_000)
            guard scenePhase == .active else { return }

            pendingSiriStart = false

            flow.selectedTab = .reflect
            try? await Task.sleep(nanoseconds: 150_000_000)

            if captureCoordinator.phase == .idle {
                captureCoordinator.startCapture()
            }

            try? await Task.sleep(nanoseconds: 900_000_000)
            guard scenePhase == .active else { return }
            if captureCoordinator.phase == .idle {
                captureCoordinator.startCapture()
            }
        }
    }
}

private struct NowPlayingMiniBar: View {
    @EnvironmentObject private var nowPlaying: NowPlayingStore

    var body: some View {
        if let item = nowPlaying.currentItem {
            HStack(spacing: 12) {
                Button {
                    nowPlaying.expand()
                } label: {
                    HStack(spacing: 12) {
                        artwork

                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.title)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.primary)
                                .lineLimit(1)

                            Text(item.subtitle)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }

                        Spacer()
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                HStack(spacing: 6) {
                    Button {
                        nowPlaying.playPrevious()
                    } label: {
                        Image(systemName: "backward.end.fill")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(nowPlaying.canPlayPrevious ? item.tint : .secondary.opacity(0.45))
                            .frame(width: 30, height: 30)
                    }
                    .buttonStyle(.plain)
                    .disabled(!nowPlaying.canPlayPrevious)

                    Button {
                        nowPlaying.toggleCurrent()
                    } label: {
                        Image(systemName: nowPlaying.isPlaying ? "pause.fill" : "play.fill")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(item.tint)
                            .frame(width: 38, height: 38)
                            .background(
                                Circle()
                                    .fill(item.tint.opacity(0.14))
                            )
                    }
                    .buttonStyle(.plain)

                    Button {
                        nowPlaying.playNext()
                    } label: {
                        Image(systemName: "forward.end.fill")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(nowPlaying.canPlayNext ? item.tint : .secondary.opacity(0.45))
                            .frame(width: 30, height: 30)
                    }
                    .buttonStyle(.plain)
                    .disabled(!nowPlaying.canPlayNext)

                    Button {
                        nowPlaying.minimizeMiniPlayer()
                    } label: {
                        Image(systemName: "chevron.down")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .frame(width: 30, height: 30)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Text("Minimize player"))
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(Color.white.opacity(0.18), lineWidth: 1)
                    )
            )
            .shadow(color: .black.opacity(0.12), radius: 14, x: 0, y: 8)
            .overlay(alignment: .topLeading) {
                GeometryReader { geo in
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(item.tint.opacity(0.94))
                        .frame(width: max(geo.size.width * playbackProgress, 18), height: 3)
                        .padding(.top, 1)
                }
            }
            .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .gesture(
                DragGesture(minimumDistance: 18)
                    .onEnded { value in
                        guard value.translation.height > 22 || abs(value.translation.width) > 42 else { return }
                        nowPlaying.minimizeMiniPlayer()
                    }
            )
        }
    }

    private var artwork: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(currentTint.opacity(0.20))

            if let assetName = nowPlaying.currentItem?.artworkAssetName {
                Image(assetName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 44, height: 44)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
        .frame(width: 44, height: 44)
    }

    private var currentTint: Color {
        nowPlaying.currentItem?.tint ?? Color.secondary
    }

    private var playbackProgress: CGFloat {
        guard nowPlaying.duration > 0 else { return 0 }
        return CGFloat(min(max(nowPlaying.currentTime / nowPlaying.duration, 0), 1))
    }
}

private struct CompactNowPlayingButton: View {
    @EnvironmentObject private var nowPlaying: NowPlayingStore

    var body: some View {
        if let item = nowPlaying.currentItem {
            Button {
                nowPlaying.restoreMiniPlayer()
            } label: {
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 52, height: 52)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.18), lineWidth: 1)
                        )

                    Image(systemName: item.artworkAssetName == nil ? "music.note" : "waveform")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(item.tint)
                }
                .shadow(color: .black.opacity(0.12), radius: 12, x: 0, y: 8)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text("Show player"))
        }
    }
}

private struct ExpandedNowPlayingView: View {
    @EnvironmentObject private var nowPlaying: NowPlayingStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.95, green: 0.94, blue: 0.91),
                        Color(red: 0.92, green: 0.90, blue: 0.85),
                        Color(red: 0.90, green: 0.91, blue: 0.93)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                if let assetName = nowPlaying.currentItem?.artworkAssetName {
                    Image(assetName)
                        .resizable()
                        .scaledToFit()
                        .ignoresSafeArea()
                        .blur(radius: 28)
                        .scaleEffect(1.34)
                        .opacity(0.08)
                }

                if let item = nowPlaying.currentItem {
                    VStack(spacing: 24) {
                        if let assetName = item.artworkAssetName {
                            Image(assetName)
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: .infinity)
                                .frame(height: 388)
                        } else {
                            Image("cloudbg")
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: .infinity)
                                .frame(height: 388)
                                .opacity(0.22)
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text(item.title)
                                .font(.system(.title2, design: .serif).weight(.bold))

                            Text(item.subtitle)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        VStack(spacing: 8) {
                            Slider(
                                value: Binding(
                                    get: { nowPlaying.currentTime },
                                    set: { nowPlaying.seek(to: $0) }
                                ),
                                in: 0...max(nowPlaying.duration, 0.01)
                            )
                            .tint(item.tint)

                            HStack {
                                Text(mmss(nowPlaying.currentTime))
                                Spacer()
                                Text(mmss(nowPlaying.duration))
                            }
                            .font(.footnote.monospacedDigit())
                            .foregroundStyle(.secondary)
                        }

                        HStack(spacing: 32) {
                            Button {
                                nowPlaying.playPrevious()
                            } label: {
                                Image(systemName: "backward.end.fill")
                                    .font(.title2.weight(.semibold))
                            }
                            .buttonStyle(.plain)

                            Button {
                                nowPlaying.toggleCurrent()
                            } label: {
                                ZStack {
                                    Circle()
                                        .fill(item.tint)
                                        .frame(width: 78, height: 78)

                                    Image(systemName: nowPlaying.isPlaying ? "pause.fill" : "play.fill")
                                        .font(.system(size: 28, weight: .bold))
                                        .foregroundStyle(.white)
                                        .offset(x: nowPlaying.isPlaying ? 0 : 2)
                                }
                            }
                            .buttonStyle(.plain)

                            Button {
                                nowPlaying.playNext()
                            } label: {
                                Image(systemName: "forward.end.fill")
                                    .font(.title2.weight(.semibold))
                            }
                            .buttonStyle(.plain)
                        }
                        .foregroundStyle(.primary)

                        Spacer()
                    }
                    .padding(20)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        nowPlaying.collapse()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.headline.weight(.semibold))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func mmss(_ seconds: TimeInterval) -> String {
        let totalSeconds = max(0, Int(seconds.rounded()))
        return String(format: "%d:%02d", totalSeconds / 60, totalSeconds % 60)
    }
}
