//
//  ContemplationService.swift
//  Clarity
//

import Foundation

final class ContemplationService {
    private let cloudTap: CloudTapSettings
    private let providerSettings: ContemplationProviderSettings

    init(cloudTap: CloudTapSettings, providerSettings: ContemplationProviderSettings) {
        self.cloudTap = cloudTap
        self.providerSettings = providerSettings
    }

    func generate(_ request: ContemplationRequest) async throws -> ContemplationResponse {
        let provider = try resolveProvider(for: request.mode)
        return try await provider.generate(request)
    }

    private func resolveProvider(for mode: ContemplationMode) throws -> ContemplationProvider {
        // Talk-it-through is cloud-only for now.
        if mode == .talkItThrough {
            return try resolveCloudTapProvider()
        }

        switch providerSettings.choice {
        case .cloudTap:
            return try resolveCloudTapProvider()

        case .deviceTapApple:
            return AppleFMProvider()

        case .deviceTapLlama:
            return LocalLlamaProvider()


        case .auto:
            // Only pick Apple FM when it is *actually* available.
            if AppleFMProvider.isAvailable() {
                return AppleFMProvider()
            }
            return try resolveCloudTapProvider()
        }
    }

    private func resolveCloudTapProvider() throws -> ContemplationProvider {
        guard cloudTap.isEnabled else {
            throw ContemplationProviderError.unavailable("Cloud Tap is disabled in Privacy settings.")
        }
        guard case .available = CloudTapConfig.availability() else {
            throw ContemplationProviderError.unavailable("Cloud Tap is not configured on this build.")
        }
        let service = CloudTapService(
            baseURL: CloudTapConfig.baseURL,
            anonKey: CloudTapConfig.supabaseAnonKey
        )
        return CloudTapProvider(service: service)
    }
}

