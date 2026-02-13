// FILE: Clarity/Core/Portrait/UserProfileStore.swift

import Foundation
import Combine
import SwiftData

@MainActor
final class UserProfileStore: ObservableObject {

    @Published private(set) var recipe: PortraitRecipe = .default
    @Published private(set) var lastError: String? = nil

    private weak var modelContext: ModelContext?
    private var entity: UserProfileEntity? = nil

    init() {}

    /// Call once when you have a ModelContext (e.g. in ProfileHubView / ProgressScreen).
    func attach(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadOrCreate()
    }

    func reload() {
        loadOrCreate()
    }

    func save(recipe newRecipe: PortraitRecipe) {
        guard let modelContext else {
            lastError = "UserProfileStore.save called before attach(modelContext:)"
            return
        }

        let row = entity ?? fetchSingleton(in: modelContext) ?? UserProfileEntity()

        row.portraitRecipeJSON = newRecipe.encode()
        row.updatedAt = Date()

        if entity == nil {
            modelContext.insert(row)
            entity = row
        }

        do {
            try modelContext.save()
            recipe = newRecipe
            lastError = nil
        } catch {
            lastError = "SwiftData save failed: \(error.localizedDescription)"
        }
    }

    // MARK: - Private

    private func loadOrCreate() {
        guard let modelContext else {
            lastError = "UserProfileStore.loadOrCreate called before attach(modelContext:)"
            return
        }

        if let existing = fetchSingleton(in: modelContext) {
            entity = existing
            recipe = PortraitRecipe.decodeOrDefault(from: existing.portraitRecipeJSON)
            lastError = nil
            return
        }

        let created = UserProfileEntity()
        modelContext.insert(created)

        do {
            try modelContext.save()
            entity = created
            recipe = PortraitRecipe.decodeOrDefault(from: created.portraitRecipeJSON)
            lastError = nil
        } catch {
            lastError = "SwiftData initial save failed: \(error.localizedDescription)"
        }
    }

    private func fetchSingleton(in modelContext: ModelContext) -> UserProfileEntity? {
        do {
            let descriptor = FetchDescriptor<UserProfileEntity>(
                predicate: #Predicate { $0.id == "singleton" }
            )
            return try modelContext.fetch(descriptor).first
        } catch {
            lastError = "SwiftData fetch failed: \(error.localizedDescription)"
            return nil
        }
    }
}
