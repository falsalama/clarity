import Foundation

final class LocalLlamaProvider: ContemplationProvider {

    private let modelManager = LocalModelManager.shared
    private var bridge: LlamaBridge?

    func generate(_ request: ContemplationRequest) async throws -> ContemplationResponse {
        guard modelManager.isInstalled else {
            throw ContemplationProviderError.unavailable("Local model not installed.")
        }

        // If Talk-it-through remains cloud-only, enforce it here too
        if request.mode == .talkItThrough {
            throw ContemplationProviderError.unavailable("Talk-it-through is cloud-only on this build.")
        }

        let modelPath = modelManager.expectedPathForUI

        if bridge == nil {
            var err: NSError?
            let b = LlamaBridge(modelPath: modelPath, error: &err)
            if let err {
                throw ContemplationProviderError.unavailable("Failed to load local model: \(err.localizedDescription)")
            }
            bridge = b
        }

        let prompt = LocalPrompt.build(mode: request.mode, userText: request.text)

        return try await withCheckedThrowingContinuation { cont in
            DispatchQueue.global(qos: .userInitiated).async {
                var err: NSError?
                let raw = self.bridge?.generate(withPrompt: prompt, maxTokens: 350, temperature: 0.2, error: &err) ?? ""

                if let err {
                    cont.resume(throwing: ContemplationProviderError.unavailable("Local generation failed: \(err.localizedDescription)"))
                    return
                }

                let cleaned = raw.trimmingCharacters(in: .whitespacesAndNewlines)

                cont.resume(returning: ContemplationResponse(
                    text: cleaned.isEmpty ? "No output." : cleaned,
                    promptVersion: "local_llama_v1",
                    providerLane: .local
                ))
            }
        }
    }
}

enum LocalPrompt {
    static func build(mode: ContemplationMode, userText: String) -> String {
        let rules =
"""
You are Clarity.
Do not decide for the user.
No diagnosis. No identity claims. No metaphysics.
Be brief and structured.
"""

        let modeLine: String = {
            switch mode {
            case .reflect:
                return "Mode: Reflect\nReturn: what feels present; what may be shaping; what loosens if held lightly."
            case .perspective:
                return "Mode: Perspective\nReturn: 2–4 lenses, each 1–2 lines. No advice."
            case .options:
                return "Mode: Options\nReturn: 3–6 options, each with a tradeoff. No pushing."
            case .questions:
                return "Mode: Questions\nReturn: 5–10 clarifying questions. No advice."
            case .talkItThrough:
                return "Mode: Talk-it-through"
            }
        }()

        // keep it short for local inference
        let clippedUser = String(userText.prefix(4000))

        return """
\(rules)

\(modeLine)

User:
\(clippedUser)

Response:
"""
    }
}

