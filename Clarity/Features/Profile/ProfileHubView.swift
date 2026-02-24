import SwiftUI
import SwiftData

struct ProfileHubView: View {
    // Progress counters
    @Query private var reflectCompletions: [ReflectCompletionEntity]
    @Query private var focusCompletions: [FocusCompletionEntity]
    @Query private var practiceCompletions: [PracticeCompletionEntity]

    // User profile singleton
    @Query private var userProfiles: [UserProfileEntity]

    // Calendar
    @StateObject private var calendarStore = CalendarStore()

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
        .task {
            await calendarStore.refresh()
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                let reflectCount = min(108, reflectCompletions.count)
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
