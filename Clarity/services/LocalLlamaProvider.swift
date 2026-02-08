//
//  LocalLlamaProvider.swift
//  Clarity
//
//  Created by Danny Griffin on 08/02/2026.
//

import Foundation

final class LocalLlamaProvider: ContemplationProvider {

    private let modelManager = LocalModelManager.shared

    func generate(_ request: ContemplationRequest) async throws -> ContemplationResponse {
        guard modelManager.isInstalled else {
            throw ContemplationProviderError.unavailable(
                "Local model not installed. Download it in Settings."
            )
        }

        // Runtime not wired yet
        throw ContemplationProviderError.unavailable(
            "Local Llama runtime not connected yet."
        )
    }
}
