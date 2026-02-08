import Foundation

final class LocalLlamaProvider {
    static let shared = LocalLlamaProvider()

    private let engine = LocalLlamaEngine()
    private var didLoad = false

    private init() {}

    // Looks for the first .gguf inside "Application Support/models" (canonical),
    // then "Application Support/Models" (legacy), then legacy root "model.gguf".
    private func modelURLInAppSupport() throws -> URL {
        let fm = FileManager.default
        let appSupport = try fm.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )

        let canonicalDir = appSupport.appendingPathComponent("models", isDirectory: true)
        let legacyDir = appSupport.appendingPathComponent("Models", isDirectory: true)

        // Search canonical first, then legacy.
        for dir in [canonicalDir, legacyDir] {
            if fm.fileExists(atPath: dir.path) {
                let contents = try fm.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)
                if let gguf = contents.first(where: { $0.pathExtension.lowercased() == "gguf" }) {
                    #if DEBUG
                    print("LocalLlamaProvider: using model at \(gguf.path)")
                    #endif
                    return gguf
                }
            }
        }

        // Backward compatibility: root-level "model.gguf" inside Application Support.
        let legacyRoot = appSupport.appendingPathComponent("model.gguf")
        if fm.fileExists(atPath: legacyRoot.path) {
            #if DEBUG
            print("LocalLlamaProvider: using legacy root model at \(legacyRoot.path)")
            #endif
            return legacyRoot
        }

        throw NSError(
            domain: "LocalLlamaProvider",
            code: 1,
            userInfo: [
                NSLocalizedDescriptionKey:
                    "No .gguf model found. Looked in:\n" +
                    "- \(canonicalDir.path)\n" +
                    "- \(legacyDir.path)\n" +
                    "- \(legacyRoot.path)"
            ]
        )
    }

    // Optional helper for "auto" checks or diagnostics.
    static func isAvailable() -> Bool {
        do {
            _ = try LocalLlamaProvider.shared.modelURLInAppSupport()
            return true
        } catch {
            return false
        }
    }

    func warmUpIfNeeded() async throws {
        if didLoad { return }
        let url = try modelURLInAppSupport()

        // Choose a sensible default for threads; leave one core free if possible.
        let cores = max(2, ProcessInfo.processInfo.activeProcessorCount)
        let nThreads = max(1, cores - 1)

        try await engine.loadModel(at: url.path, nCtx: 2048, nBatch: 512, nThreads: Int32(nThreads))
        didLoad = true
    }

    func generate(prompt: String, maxTokens: Int = 128, temperature: Float = 0.2) async throws -> String {
        try await warmUpIfNeeded()
        return try await engine.generate(prompt: prompt, maxTokens: maxTokens, temperature: temperature)
    }

    // Now async because LocalLlamaEngine.shutdown is actor-isolated.
    func shutdown() async {
        await engine.shutdown()
        didLoad = false
    }
}

extension LocalLlamaProvider: ContemplationProvider {
    func generate(_ request: ContemplationRequest) async throws -> ContemplationResponse {
        // Defensive: service shouldn't route talk-it-through here.
        if request.mode == .talkItThrough {
            throw ContemplationProviderError.unavailable("Talk-it-through is not supported on Device Tap yet.")
        }

        let system = Self.systemInstruction(for: request.mode)
        let prompt = Self.llamaChatPrompt(system: system, user: request.text)

        do {
            let raw = try await self.generate(prompt: prompt, maxTokens: 256, temperature: 0.2)
            let cleaned = Self.normalizeOutput(raw, for: request.mode)
            return ContemplationResponse(
                text: cleaned,
                promptVersion: "localllama_v1_chat",
                providerLane: .onDevice
            )
        } catch {
            throw ContemplationProviderError.unavailable("Local Llama failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Prompting

    // Llama 3.2 chat-style headers (system → user → assistant)
    private static func llamaChatPrompt(system: String, user: String) -> String {
        """
        <|begin_of_text|><|start_header_id|>system<|end_header_id|>
        \(system)
        <|eot_id|><|start_header_id|>user<|end_header_id|>
        \(user)
        <|eot_id|><|start_header_id|>assistant<|end_header_id|>
        """
    }

    // Strong, style-stable instructions per mode (no markdown, bullets, or numbering).
    private static func systemInstruction(for mode: ContemplationMode) -> String {
        switch mode {
        case .reflect:
            return """
            You are a calm thinking instrument. Write a short contemplation in three parts:
            1) What's present. 2) What might be shaping it. 3) What loosens if held lightly.
            Style constraints (must follow):
            - Plain text only. No markdown, no headings, no bullets, no numbering.
            - Three brief paragraphs separated by blank lines.
            - No judgment. No identity claims. No therapy framing.
            """

        case .perspective:
            return """
            Offer three alternative perspectives on the user's text.
            Style constraints (must follow):
            - Plain text only. No markdown, no headings, no bullets, no numbering.
            - Three brief paragraphs separated by blank lines.
            - Calm, non‑preachy. No identity claims.
            """

        case .options:
            return """
            List four options the user could consider, phrased as possibilities, not advice.
            Style constraints (must follow):
            - Plain text only. No markdown, no headings, no bullets, no numbering.
            - Output exactly four short sentences, each on its own line.
            - Keep agency with the user.
            """

        case .questions:
            return """
            Provide three contemplation questions that loosen grasping.
            Style constraints (must follow):
            - Plain text only. No markdown, no headings, no bullets, no numbering.
            - Output exactly three short questions, one per line.
            - Keep them simple and direct.
            """

        case .talkItThrough:
            return "Talk-it-through is not supported on Device Tap yet."
        }
    }

    // MARK: - Output normalization

    // Remove markdown headings, bullets, and numbering at line starts.
    private static func normalizeOutput(_ text: String, for mode: ContemplationMode) -> String {
        let lines = text.components(separatedBy: .newlines).map { line -> String in
            var s = line

            // Trim leading/trailing spaces first
            s = s.trimmingCharacters(in: .whitespaces)

            // Strip markdown heading markers like "#", "##", etc.
            s = s.replacingOccurrences(of: #"^\s*#{1,6}\s*"#, with: "", options: .regularExpression)

            // Strip common bullets: -, *, •, –, —
            s = s.replacingOccurrences(of: #"^\s*[-*•–—]\s+"#, with: "", options: .regularExpression)

            // Strip numeric/roman enumerations: "1. ", "1) ", "(1) ", "I. ", "i) "
            s = s.replacingOccurrences(of: #"^\s*\(?\d+\)?[.)]\s+"#, with: "", options: .regularExpression)
            s = s.replacingOccurrences(of: #"^\s*[ivxlcdmIVXLCDM]+[.)]\s+"#, with: "", options: .regularExpression)

            // Remove bold markers like **text** or __text__
            s = s.replacingOccurrences(of: "**", with: "")
            s = s.replacingOccurrences(of: "__", with: "")

            return s
        }

        var out = lines.joined(separator: "\n")

        // Collapse excessive blank lines
        out = out.replacingOccurrences(of: #"\n{3,}"#, with: "\n\n", options: .regularExpression)

        // Final trim
        out = out.trimmingCharacters(in: .whitespacesAndNewlines)

        return out
    }
}
