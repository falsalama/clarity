import SwiftUI
import SwiftData

struct ProfileHubView: View {
    @EnvironmentObject private var flow: AppFlowRouter
    @EnvironmentObject private var reflectStore: ClarityReflectStore

    @Query private var reflectCompletions: [ReflectCompletionEntity]
    @Query private var focusCompletions: [FocusCompletionEntity]
    @Query private var practiceCompletions: [PracticeCompletionEntity]
    @Query private var userProfiles: [UserProfileEntity]

    @State private var showProgressScreen: Bool = false
    @State private var revealPoint: CGPoint? = nil
    @State private var revealAmount: CGFloat = 0

    private let revealSize: CGFloat = 340

    init() {
        _reflectCompletions = Query(
            sort: [SortDescriptor(\ReflectCompletionEntity.completedAt, order: .reverse)]
        )

        _focusCompletions = Query(
            sort: [SortDescriptor(\FocusCompletionEntity.completedAt, order: .reverse)]
        )

        _practiceCompletions = Query(
            sort: [SortDescriptor(\PracticeCompletionEntity.completedAt, order: .reverse)]
        )

        _userProfiles = Query(
            filter: #Predicate<UserProfileEntity> { $0.id == "singleton" }
        )
    }

    private var portraitRecipe: PortraitRecipe {
        guard let row = userProfiles.first else { return .default }
        return PortraitRecipe.decodeOrDefault(from: row.portraitRecipeJSON)
    }

    private var dailyDoneCount: Int {
        let r = Set(reflectCompletions.map(\.dayKey))
        let f = Set(focusCompletions.map(\.dayKey))
        let p = Set(practiceCompletions.map(\.dayKey))
        return r.intersection(f).intersection(p).count
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            ProfileBackgroundView(
                revealPoint: revealPoint,
                revealAmount: revealAmount,
                revealSize: revealSize
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    sectionTitle("You")

                    VStack(alignment: .leading, spacing: 14) {
                        NavigationLink {
                            CapsuleView()
                        } label: {
                            ProfileMenuCard(
                                title: "Capsule",
                                subtitle: "Profile, preferences, and practice context.",
                                systemImage: "capsule"
                            )
                        }
                        .buttonStyle(ProfileMenuCardPressStyle())

                        NavigationLink {
                            CapsuleLearningView()
                        } label: {
                            ProfileMenuCard(
                                title: "Learning",
                                subtitle: "Learned cues and on-device response patterns.",
                                systemImage: "sparkles"
                            )
                        }
                        .buttonStyle(ProfileMenuCardPressStyle())

                        NavigationLink {
                            PortraitEditorView()
                        } label: {
                            ProfilePortraitCard(recipe: portraitRecipe)
                        }
                        .buttonStyle(ProfileMenuCardPressStyle())
                    }

                    sectionTitle("App")

                    VStack(alignment: .leading, spacing: 14) {
                        NavigationLink {
                            ClarityReflectView()
                        } label: {
                            ProfileMenuCard(
                                title: "Account",
                                subtitle: accountSubtitle,
                                systemImage: "sparkle.magnifyingglass"
                            )
                        }
                        .buttonStyle(ProfileMenuCardPressStyle())

                        NavigationLink {
                            AboutView()
                        } label: {
                            ProfileMenuCard(
                                title: "About",
                                subtitle: "What Clarity is and how it works.",
                                systemImage: "info.circle"
                            )
                        }
                        .buttonStyle(ProfileMenuCardPressStyle())

                        NavigationLink {
                            SettingsView()
                        } label: {
                            ProfileMenuCard(
                                title: "Settings",
                                subtitle: "App settings and processing choices.",
                                systemImage: "gearshape"
                            )
                        }
                        .buttonStyle(ProfileMenuCardPressStyle())

                        NavigationLink {
                            PrivacyView()
                        } label: {
                            ProfileMenuCard(
                                title: "Privacy",
                                subtitle: "Cloud Tap, redaction, and local controls.",
                                systemImage: "hand.raised"
                            )
                        }
                        .buttonStyle(ProfileMenuCardPressStyle())
                    }
                }
                .padding(16)
                .padding(.bottom, 24)
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }
        }
        .simultaneousGesture(
            SpatialTapGesture()
                .onEnded { value in
                    revealPoint = value.location
                    withAnimation(.easeOut(duration: 0.14)) {
                        revealAmount = 1
                    }
                    withAnimation(.easeOut(duration: 0.80).delay(0.04)) {
                        revealAmount = 0
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.90) {
                        if revealAmount == 0 {
                            revealPoint = nil
                        }
                    }
                }
        )
        .simultaneousGesture(
            DragGesture(minimumDistance: 8, coordinateSpace: .local)
                .onChanged { value in
                    revealPoint = value.location
                    withAnimation(.easeOut(duration: 0.14)) {
                        revealAmount = 1
                    }
                }
                .onEnded { _ in
                    withAnimation(.easeOut(duration: 0.85)) {
                        revealAmount = 0
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.90) {
                        if revealAmount == 0 {
                            revealPoint = nil
                        }
                    }
                }
        )
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    ProgressScreen()
                } label: {
                    DailyDoneCapsule(count: dailyDoneCount)
                }
                .accessibilityLabel(Text("Progress - Daily completions \(dailyDoneCount)"))
            }
        }
        .onAppear {
            if flow.pendingOpenProgress {
                flow.consumeProgressTrigger()
                showProgressScreen = true
            }
        }
        .onChange(of: flow.pendingOpenProgress) { _, newValue in
            guard newValue else { return }
            flow.consumeProgressTrigger()
            showProgressScreen = true
        }
        .navigationDestination(isPresented: $showProgressScreen) {
            ProgressScreen()
        }
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.headline)
            .foregroundStyle(.secondary)
    }

    private var accountSubtitle: String {
        if reflectStore.isSupportOnlyActive {
            return "Support Clarity active."
        }
        if reflectStore.hasPaidTier {
            return "Manage Clarity Reflect and support."
        }
        return "Core app free. Paid Reflect tools are optional."
    }
}

// MARK: - Profile background

private struct ProfileBackgroundView: View {
    let revealPoint: CGPoint?
    let revealAmount: CGFloat
    let revealSize: CGFloat

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                backgroundImage(named: "profilebg", in: proxy)
                    .opacity(0.60)

                if let revealPoint {
                    backgroundImage(named: "profilebgcol", in: proxy)
                        .opacity(revealAmount * 0.98)
                        .mask {
                            ZStack {
                                Color.clear

                                Circle()
                                    .fill(
                                        RadialGradient(
                                            stops: [
                                                .init(color: .white.opacity(1.0), location: 0.00),
                                                .init(color: .white.opacity(0.92), location: 0.20),
                                                .init(color: .white.opacity(0.70), location: 0.42),
                                                .init(color: .white.opacity(0.34), location: 0.68),
                                                .init(color: .clear, location: 1.00)
                                            ],
                                            center: .center,
                                            startRadius: 0,
                                            endRadius: revealSize * (0.46 + (revealAmount * 0.10))
                                        )
                                    )
                                    .frame(
                                        width: revealSize * (0.94 + revealAmount * 0.08),
                                        height: revealSize * (0.94 + revealAmount * 0.08)
                                    )
                                    .position(revealPoint)
                                    .blur(radius: 24)
                            }
                            .compositingGroup()
                        }
                }
            }
        }
        .allowsHitTesting(false)
    }

    private func backgroundImage(named name: String, in proxy: GeometryProxy) -> some View {
        let overscanWidth = proxy.size.width * 1.14
        let overscanHeight = proxy.size.height * 1.26

        return Image(name)
            .resizable()
            .scaledToFill()
            .frame(width: overscanWidth, height: overscanHeight)
            .offset(y: proxy.size.height * 0.07)
            .clipped()
            .ignoresSafeArea()
    }
}

private struct ProfileMenuCard: View {
    let title: String
    let subtitle: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.title3)
                .foregroundStyle(.primary.opacity(0.72))
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(.systemBackground).opacity(0.34))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.primary.opacity(0.14), lineWidth: 1)
        )
    }
}

private struct ProfilePortraitCard: View {
    let recipe: PortraitRecipe

    var body: some View {
        HStack(spacing: 12) {
            PortraitView(recipe: recipe)
                .frame(width: 62, height: 62)

            VStack(alignment: .leading, spacing: 4) {
                Text("Portrait")
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text("Portrait style, appearance, and expression.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(.systemBackground).opacity(0.34))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.primary.opacity(0.14), lineWidth: 1)
        )
    }
}

private struct ProfileMenuCardPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(
                        Color.primary.opacity(configuration.isPressed ? 0.30 : 0.18),
                        lineWidth: configuration.isPressed ? 1.5 : 1
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.992 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}
