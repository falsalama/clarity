import SwiftUI
import SwiftData

struct ProfileHubView: View {
    // Progress counters
    @Query private var completedTurns: [TurnEntity]
    @Query private var focusCompletions: [FocusCompletionEntity]
    @Query private var practiceCompletions: [PracticeCompletionEntity]

    // User profile singleton
    @Query private var userProfiles: [UserProfileEntity]

    init() {
        _completedTurns = Query(
            filter: #Predicate<TurnEntity> { turn in
                !turn.transcriptRedactedActive.isEmpty
            }
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
                    PortraitEditorView()
                } label: {
                    HStack(spacing: 12) {
                        PortraitView(recipe: portraitRecipe)
                            .frame(width: 28, height: 28)

                        Text("Portrait")

                        Spacer()
                    }
                    .contentShape(Rectangle())
                }
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
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                let reflectCount = min(108, completedTurns.count)
                let focusCount = focusCompletions.count
                let practiceCount = practiceCompletions.count

                NavigationLink {
                    ProgressScreen()
                } label: {
                    ProgressCounterCapsule(
                        reflectCount: reflectCount,
                        focusCount: focusCount,
                        practiceCount: practiceCount
                    )
                }
                .accessibilityLabel(
                    Text("Progress — Reflect \(reflectCount), Focus \(focusCount), Practice \(practiceCount)")
                )
            }
        }
    }
}
