import SwiftUI
import SwiftData

struct ProgressScreen: View {
    @Environment(\.modelContext) private var modelContext

    @StateObject private var profileStore = UserProfileStore()
    @State private var showPortraitEditor = false

    @Query private var reflectCompletions: [ReflectCompletionEntity]
    @Query private var focusCompletions: [FocusCompletionEntity]
    @Query private var practiceCompletions: [PracticeCompletionEntity]

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
    }

    private var reflectCount: Int { min(108, reflectCompletions.count) }
    private var focusCount: Int { focusCompletions.count }
    private var practiceCount: Int { practiceCompletions.count }

    private var bloomOpenCount: Int {
        let total = max(0, reflectCount) + max(0, focusCount) + max(0, practiceCount)
        return min(108, total)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Bloom108View(
                    openCount: bloomOpenCount,
                    portraitRecipe: profileStore.recipe,
                    onPortraitTap: { showPortraitEditor = true }
                )
                .frame(maxWidth: .infinity)
                .padding(.top, 12)

                VStack(spacing: 10) {
                    ProgressCounterCapsule(
                        reflectCount: reflectCount,
                        focusCount: focusCount,
                        practiceCount: practiceCount
                    )

                    Text("\(bloomOpenCount) of 108")
                        .font(.title2.weight(.semibold))

                    Text("Bloom opens with your total completions across Reflect, Focus and Practice.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                Spacer(minLength: 10)
            }
            .padding()
        }
        .navigationTitle("Progress")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showPortraitEditor, onDismiss: {
            profileStore.attach(modelContext: modelContext)
        }) {
            NavigationStack {
                PortraitEditorView()
            }
        }
        .onAppear {
            profileStore.attach(modelContext: modelContext)
        }
    }
}

