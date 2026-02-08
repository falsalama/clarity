//
//  AppleFMProvider.swift
//  Clarity
//
//  Device Tap provider using Apple Foundation Models (system on-device model).
//

import Foundation

#if canImport(FoundationModels)
import FoundationModels
#endif

final class AppleFMProvider: ContemplationProvider {

    /// Returns true only when the system model is actually available on this runtime.
    /// (Simulator often reports unavailable because model assets are not present.)
    static func isAvailable() -> Bool {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            switch SystemLanguageModel.default.availability {
            case .available:
                return true
            case .unavailable:
                return false
            }
        }
        #endif
        return false
    }

    func generate(_ request: ContemplationRequest) async throws -> ContemplationResponse {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            let instruction = Self.instruction(for: request.mode)

            let prompt = """
            \(instruction)

            User text:
            \(request.text)
            """

            let model = SystemLanguageModel.default

            switch model.availability {
            case .available:
                break
            case .unavailable(let reason):
                // This is the common simulator case: assetsUnavailable / model not ready / not enabled etc.
                throw ContemplationProviderError.unavailable("Apple Device Tap unavailable: \(reason)")
            }

            do {
                let session = LanguageModelSession(model: model)
                let result = try await session.respond(to: prompt)

                return ContemplationResponse(
                    text: result.content,
                    promptVersion: "applefm_v1",
                    providerLane: .onDevice
                )
            } catch {
                throw ContemplationProviderError.unavailable("Apple Device Tap failed: \(error)")
            }
        } else {
            throw ContemplationProviderError.unavailable("Apple Foundation Models require iOS 26+.")
        }
        #else
        throw ContemplationProviderError.unavailable("Apple Foundation Models are not available in this build.")
        #endif
    }

    private static func instruction(for mode: ContemplationMode) -> String {
        switch mode {
        case .reflect:
            return "Write a short contemplation in 3 parts: What's present. What might be shaping it. What loosens if held lightly. No judgement. No identity claims."
        case .perspective:
            return "Offer 3 alternative perspectives, calm and non-preachy. No judgement. No identity claims."
        case .options:
            return "List 4 options the user could consider, phrased as possibilities, not advice. Keep agency with the user."
        case .questions:
            return "Provide 3 contemplation questions that loosen grasping. Keep them simple and direct."
        case .talkItThrough:
            return "Talk-it-through is not supported on Device Tap yet."
        }
    }
}

