import SwiftUI
import SwiftData

struct ProfileHubView: View {
    @EnvironmentObject private var flow: AppFlowRouter

    // Progress counters
    @Query private var reflectCompletions: [ReflectCompletionEntity]
    @Query private var focusCompletions: [FocusCompletionEntity]
    @Query private var practiceCompletions: [PracticeCompletionEntity]

    // User profile singleton
    @Query private var userProfiles: [UserProfileEntity]

    // Calendar
    @StateObject private var calendarStore = CalendarStore()

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
                    CalendarView()
                } label: {
                    HStack(spacing: 10) {
                        Label("Calendar", systemImage: "calendar")

                        Spacer()

                        if let today = calendarStore.today.first {
                            Text(today.title)
                                .font(.footnote)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
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
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .task { await calendarStore.refresh() }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                // Daily units:
                // - Legacy: day where Reflect + View + Practice all completed
                // - New: any PracticeCompletionEntity with programmeSlug == "daily_unit_v1"
                // De-duped by dayKey.
                let r = Set(reflectCompletions.map(\.dayKey))
                let f = Set(focusCompletions.map(\.dayKey))
                let p = Set(practiceCompletions.map(\.dayKey))
                let dailyDoneCount = r.intersection(f).intersection(p).count

                NavigationLink {
                    ProgressScreen()
                } label: {
                    DailyDoneCapsule(count: dailyDoneCount)
                }
                .accessibilityLabel(Text("Progress — Daily completions \(dailyDoneCount)"))
            }
        }
        .onAppear {
            if flow.pendingOpenProgress {
                flow.consumeProgressTrigger()
                showProgressScreen = true
            }
        }
        // Auto-open Progress when Practice completes.
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
