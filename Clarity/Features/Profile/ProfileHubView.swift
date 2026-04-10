import SwiftUI
import SwiftData

struct ProfileHubView: View {
    @EnvironmentObject private var flow: AppFlowRouter

    @Query private var reflectCompletions: [ReflectCompletionEntity]
    @Query private var focusCompletions: [FocusCompletionEntity]
    @Query private var practiceCompletions: [PracticeCompletionEntity]
    @Query private var userProfiles: [UserProfileEntity]

    @State private var showProgressScreen: Bool = false

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
        List {
            Section {
                NavigationLink {
                    CapsuleView()
                } label: {
                    Label("Capsule", systemImage: "capsule")
                }

                NavigationLink {
                    CapsuleLearningView()
                } label: {
                    Label("Learning", systemImage: "sparkles")
                }

                NavigationLink {
                    PortraitEditorView()
                } label: {
                    HStack(spacing: 8) {
                        PortraitView(recipe: portraitRecipe)
                            .frame(width: 65, height: 65)

                        Text("Portrait")

                        Spacer()
                    }
                    .contentShape(Rectangle())
                }
                .listRowInsets(EdgeInsets(top: 1, leading: 4, bottom: 1, trailing: 16))
            } header: {
                Text("You")
            }
            NavigationLink {
                AboutView()
            } label: {
                Label("About", systemImage: "info.circle")
            }
            Section {
                NavigationLink {
                    SettingsView()
                } label: {
                    Label("Settings", systemImage: "gearshape")
                }

                NavigationLink {
                    PrivacyView()
                } label: {
                    Label("Privacy", systemImage: "hand.raised")
                }
            } header: {
                Text("App")
            }
        }
        .scrollContentBackground(.hidden)
        .background {
            ZStack {
                Color(uiColor: .systemGroupedBackground)
                ProfileBackgroundWaterView()
            }
            .ignoresSafeArea()
        }
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
}

// MARK: - Profile background water

private struct ProfileBackgroundWaterView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var scale: CGFloat = ProfileBackgroundWaterStyle.startScale

    var body: some View {
        GeometryReader { geo in
            Image(ProfileBackgroundWaterStyle.assetName)
                .resizable()
                .scaledToFill()
                .frame(width: geo.size.width, height: geo.size.height)
                .position(x: geo.size.width / 2, y: geo.size.height / 2)
                .scaleEffect(scale, anchor: .center)
                .opacity(ProfileBackgroundWaterStyle.baseOpacity)
                .clipped()
                .allowsHitTesting(false)
                .onAppear {
                    scale = ProfileBackgroundWaterStyle.startScale
                    guard reduceMotion == false else { return }
                    withAnimation(.easeOut(duration: ProfileBackgroundWaterStyle.zoomDuration)) {
                        scale = ProfileBackgroundWaterStyle.endScale
                    }
                }
        }
    }
}

private enum ProfileBackgroundWaterStyle {
    static let assetName = "water"         // background asset name
    static let baseOpacity: Double = 0.10  // opacity
    static let startScale: CGFloat = 1.00  // start size
    static let endScale: CGFloat = 1.20    // end size
    static let zoomDuration: Double = 50   // one-shot slow zoom
}
