import SwiftUI
import SwiftData

struct WisdomView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase

    @Query(
        sort: [SortDescriptor(\WisdomResponseEntity.completedAt, order: .reverse)]
    )
    private var responses: [WisdomResponseEntity]

    @Query(
        filter: #Predicate<WisdomProgramStateEntity> { $0.id == "singleton" }
    )
    private var programStates: [WisdomProgramStateEntity]

    @State private var route: WisdomRoute?

    private let wisdomFill = Color(red: 0.48, green: 0.18, blue: 0.22)

    private var activeSets: [WisdomDailySet] {
        WisdomSeedData.activeDailySets
    }

    private var todayKey: String {
        Date().dayKey()
    }

    private var programState: WisdomProgramStateEntity? {
        programStates.first
    }

    private var currentSet: WisdomDailySet? {
        guard !activeSets.isEmpty else { return nil }
        let rawIndex = programState?.currentSetIndex ?? 0
        let safeIndex = min(max(0, rawIndex), activeSets.count - 1)
        return activeSets[safeIndex]
    }

    private var todayResponse: WisdomResponseEntity? {
        responses.first(where: { $0.dayKey == todayKey })
    }

    private var isDoneToday: Bool {
        todayResponse != nil
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                introCard

                if let set = currentSet {
                    todayHeader(for: set)

                    if let response = todayResponse {
                        doneTodayCard(for: response)
                    } else {
                        laneCards(for: set)
                    }
                } else {
                    unavailableCard
                }
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("Wisdom")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(item: $route) { route in
            WisdomCaptureView(
                dailySet: route.dailySet,
                lane: route.lane
            )
        }
        .onAppear {
            ensureProgramStateExists()
            applyDailyAdvanceIfNeeded()
        }
        .onChange(of: scenePhase) { _, newValue in
            guard newValue == .active else { return }
            ensureProgramStateExists()
            applyDailyAdvanceIfNeeded()
        }
    }

    private var introCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                Image(systemName: "sparkles.rectangle.stack.fill")
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 52, height: 52)
                    .background(wisdomFill)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text("Wisdom")
                        .font(.title3.weight(.semibold))

                    Text("One of three enquiries each day")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            Text("Choose one enquiry each day, answer in your own words, then compare your view with Buddhist, philosophical, logical, and modern perspectives.")
                .foregroundStyle(.secondary)

            Text("This is not Reflect. It is a deeper philosophical practice for opening fixation through reasoning, perspective, and contemplative analysis.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func todayHeader(for set: WisdomDailySet) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Today’s enquiries")
                .font(.headline)

            Text(set.title)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if !isDoneToday {
                Text("Choose one.")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func laneCards(for set: WisdomDailySet) -> some View {
        VStack(spacing: 12) {
            Button {
                route = WisdomRoute(dailySet: set, lane: .opening)
            } label: {
                WisdomLaneCard(
                    lane: .opening,
                    question: set.question(for: .opening),
                    accent: wisdomFill
                )
            }
            .buttonStyle(.plain)

            Button {
                route = WisdomRoute(dailySet: set, lane: .analytical)
            } label: {
                WisdomLaneCard(
                    lane: .analytical,
                    question: set.question(for: .analytical),
                    accent: wisdomFill
                )
            }
            .buttonStyle(.plain)

            Button {
                route = WisdomRoute(dailySet: set, lane: .debate)
            } label: {
                WisdomLaneCard(
                    lane: .debate,
                    question: set.question(for: .debate),
                    accent: wisdomFill
                )
            }
            .buttonStyle(.plain)
        }
    }

    private func doneTodayCard(for response: WisdomResponseEntity) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Done for today")
                    .font(.headline)

                Spacer()

                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.secondary)
            }

            Text(response.lane.title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            Text(response.questionText)
                .font(.subheadline)

            Text("A new set of enquiries will appear tomorrow.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var unavailableCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Wisdom")
                .font(.headline)

            Text("No enquiry sets are available yet.")
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func ensureProgramStateExists() {
        guard programState == nil else { return }
        modelContext.insert(WisdomProgramStateEntity())
        try? modelContext.save()
    }

    private func applyDailyAdvanceIfNeeded() {
        guard let state = programState else { return }
        guard !activeSets.isEmpty else { return }
        guard let pendingDay = state.pendingAdvanceDayKey, pendingDay < todayKey else { return }

        state.currentSetIndex = min(state.currentSetIndex + 1, activeSets.count - 1)
        state.pendingAdvanceDayKey = nil
        state.updatedAt = Date()

        try? modelContext.save()
    }
}

private struct WisdomLaneCard: View {
    let lane: WisdomLane
    let question: WisdomQuestion
    let accent: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(lane.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(accent)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(accent.opacity(0.75))
            }

            Text(question.questionText)
                .font(.headline)
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(lane.subtitle)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .contentShape(Rectangle())
    }
}

private struct WisdomRoute: Identifiable, Hashable {
    let id = UUID()
    let dailySet: WisdomDailySet
    let lane: WisdomLane
}
