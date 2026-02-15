import Foundation
import LlamaSwift

// Swift-only wrapper around llama.cpp C API via LlamaSwift package.
// Holds the model/context pointers and provides a simple generate() call.

actor LocalLlamaEngine {
    enum EngineError: Error, LocalizedError {
        case emptyModelPath
        case modelLoadFailed(String)
        case contextCreateFailed
        case tokenizationFailed
        case decodeFailed(String)

        var errorDescription: String? {
            switch self {
            case .emptyModelPath:
                return "Missing model path"
            case .modelLoadFailed(let path):
                return "Failed to load model at: \(path)"
            case .contextCreateFailed:
                return "Failed to create llama context"
            case .tokenizationFailed:
                return "Tokenisation failed"
            case .decodeFailed(let where_):
                return "llama_decode failed (\(where_))"
            }
        }
    }

    // Reversible sampling switch.
    enum SamplingMode: Equatable {
        case legacyFullSoftmax
        case topKTopP(topK: Int, topP: Float, repetitionPenalty: Float, lastN: Int)
    }

    private var model: OpaquePointer?
    private var context: OpaquePointer?
    private var vocab: OpaquePointer?
    private var didInitBackend = false

    // Remember the batch size we configured so we can chunk large prompts.
    private var nBatchUsed: Int32 = 512

    // Default to legacy for identical behavior; you can opt into the fast mode at runtime.
    private var samplingMode: SamplingMode = .legacyFullSoftmax

    // Cache the context params so we can recreate a fresh context per request (stateless generation).
    private var cachedContextParams: llama_context_params?

    deinit {
        // Actor deinit is nonisolated; use a static helper to free resources safely.
        LocalLlamaEngine.freeResources(
            context: context,
            model: model,
            didInitBackend: didInitBackend
        )
    }

    func setSamplingMode(_ mode: SamplingMode) {
        samplingMode = mode
    }

    func loadModel(
        at modelPath: String,
        nCtx: Int32 = 2048,
        nBatch: Int32 = 512,
        nThreads: Int32 = 4
    ) throws {
        if model != nil || context != nil {
            // already loaded - no-op
            return
        }

        guard modelPath.isEmpty == false else { throw EngineError.emptyModelPath }

        if !didInitBackend {
            llama_backend_init()
            didInitBackend = true
        }

        let mparams = llama_model_default_params()
        guard let m = llama_model_load_from_file(modelPath, mparams) else {
            throw EngineError.modelLoadFailed(modelPath)
        }

        var cparams = llama_context_default_params()
        cparams.n_ctx = UInt32(nCtx)
        cparams.n_batch = UInt32(nBatch)

        // Some builds expose threading via these fields; some don’t.
        // If your headers have them, set them:
        // cparams.n_threads = UInt32(nThreads)
        // cparams.n_threads_batch = UInt32(nThreads)

        // Cache params for per-request context recreation.
        cachedContextParams = cparams

        guard let ctx = llama_init_from_model(m, cparams) else {
            llama_model_free(m)
            throw EngineError.contextCreateFailed
        }

        model = m
        context = ctx
        vocab = llama_model_get_vocab(m)
        nBatchUsed = nBatch
    }

    // Actor-isolated shutdown for explicit, manual cleanup.
    // Callers should use: `await engine.shutdown()`
    func shutdown() {
        LocalLlamaEngine.freeResources(
            context: context,
            model: model,
            didInitBackend: didInitBackend
        )

        context = nil
        model = nil
        vocab = nil
        cachedContextParams = nil
        didInitBackend = false
    }

    // Nonisolated helper used by both deinit and shutdown to perform the C-level frees.
    private static func freeResources(
        context: OpaquePointer?,
        model: OpaquePointer?,
        didInitBackend: Bool
    ) {
        if let ctx = context {
            llama_free(ctx)
        }
        if let m = model {
            llama_model_free(m)
        }
        if didInitBackend {
            llama_backend_free()
        }
    }

    // Recreate a fresh llama context for each independent request.
    // This avoids KV/cache accumulation across Reflect -> Perspective -> Options -> Questions.
    private func resetContextForNewRequest() throws {
        guard let m = model, let params = cachedContextParams else { return }

        if let ctx = context {
            llama_free(ctx)
            context = nil
        }

        guard let newCtx = llama_init_from_model(m, params) else {
            throw EngineError.contextCreateFailed
        }

        context = newCtx
        // vocab remains valid for the model; no need to re-fetch.
    }

    func generate(prompt: String, maxTokens: Int, temperature: Float) throws -> String {
        guard model != nil, vocab != nil else {
            return ""
        }
        if prompt.isEmpty { return "" }

        // Ensure a clean context per request (no cross-request KV/cache).
        try resetContextForNewRequest()

        guard let ctx = context, let v = vocab else {
            return ""
        }

        // Tokenize
        let utf8Count = prompt.utf8.count
        let maxTokenCount = utf8Count + 1
        var tokens = [llama_token](repeating: 0, count: maxTokenCount)

        let tokenCount = llama_tokenize(
            v,
            prompt,
            Int32(utf8Count),
            &tokens,
            Int32(maxTokenCount),
            true,  // add BOS
            true   // special tokens
        )

        guard tokenCount > 0 else { throw EngineError.tokenizationFailed }
        let promptTokens = Array(tokens.prefix(Int(tokenCount)))

        // Decode the prompt in chunks no larger than nBatchUsed.
        let chunkCapacity = max(1, Int(nBatchUsed))
        var batch = llama_batch_init(Int32(chunkCapacity), 0, 1)
        defer { llama_batch_free(batch) }

        var nCur: Int32 = 0
        var idx = 0
        while idx < promptTokens.count {
            let m = min(chunkCapacity, promptTokens.count - idx)
            batch.n_tokens = Int32(m)
            for i in 0..<m {
                batch.token[i] = promptTokens[idx + i]

                // llama_pos is Int32
                batch.pos[i] = nCur + Int32(i)

                batch.n_seq_id[i] = 1
                if let seq_ids = batch.seq_id, let seq0 = seq_ids[i] {
                    seq0[0] = 0
                }
                // Only ask for logits on the last token in this chunk
                batch.logits[i] = (i == m - 1) ? 1 : 0
            }

            guard llama_decode(ctx, batch) == 0 else {
                throw EngineError.decodeFailed("prompt chunk")
            }

            nCur += Int32(m)
            idx += m
        }

        var output = ""

        // For fast mode: track recent tokens for repetition penalty.
        var lastTokens: [llama_token] = []
        var lastN: Int = 0
        switch samplingMode {
        case .legacyFullSoftmax:
            break
        case .topKTopP(_, _, _, let ln):
            lastN = max(0, ln)
            if lastN > 0 {
                let tail = promptTokens.suffix(lastN)
                lastTokens.reserveCapacity(lastN)
                lastTokens.append(contentsOf: tail)
            }
        }

        // Generation loop
        for _ in 0..<maxTokens {
            // logits for last processed token (prompt or generated)
            guard let logits = llama_get_logits_ith(ctx, batch.n_tokens - 1) else {
                throw EngineError.decodeFailed("get_logits")
            }

            let vocabSize = Int(llama_vocab_n_tokens(v))
            let nextToken: llama_token

            switch samplingMode {
            case .legacyFullSoftmax:
                if temperature <= 0.01 {
                    // Greedy argmax (no expf across vocab)
                    var best = logits[0]
                    var bestIdx = 0
                    if vocabSize > 1 {
                        for i in 1..<vocabSize {
                            if logits[i] > best {
                                best = logits[i]
                                bestIdx = i
                            }
                        }
                    }
                    nextToken = llama_token(bestIdx)
                } else {
                    // Full-vocab softmax (original path)
                    var maxLogit = logits[0]
                    if vocabSize > 1 {
                        for i in 1..<vocabSize { maxLogit = max(maxLogit, logits[i]) }
                    }

                    var probs = [Float](repeating: 0, count: vocabSize)
                    var sum: Float = 0
                    let t = max(0.01, temperature)
                    for i in 0..<vocabSize {
                        let v0 = (logits[i] - maxLogit) / t
                        let p = expf(v0)
                        probs[i] = p
                        sum += p
                    }

                    let r = Float.random(in: 0..<sum)
                    var acc: Float = 0
                    var picked = 0
                    for i in 0..<vocabSize {
                        acc += probs[i]
                        if acc >= r { picked = i; break }
                    }
                    nextToken = llama_token(picked)
                }

            case .topKTopP(let topK, let topP, let repetitionPenalty, let ln):
                // Efficient sampling: restrict to top-K, then apply top-P on that set.
                let k = max(1, min(topK, vocabSize))
                let t = max(0.01, temperature)

                // 1) Find top-K logits and ids; skip control/special tokens (except EOG).
                let eos = llama_vocab_eos(v)
                var topScores = [Float]()
                var topIds = [Int]()
                topScores.reserveCapacity(k)
                topIds.reserveCapacity(k)

                var filled = 0
                var minIndex = 0
                var minScore = Float.infinity

                // Precompute repetition set (small; O(ln))
                var repSet = Set<Int32>()
                if ln > 0 && !lastTokens.isEmpty {
                    repSet = Set<Int32>(lastTokens.map { $0 })
                }

                for i in 0..<vocabSize {
                    let tok = llama_token(i)
                    // Filter out control/special tokens, but allow end-of-generation tokens.
                    if isSpecialControlToken(v, tok), !isEogLikeToken(v, tok, eosFallback: eos) {
                        continue
                    }

                    let s = logits[i]

                    if filled < k {
                        topScores.append(s)
                        topIds.append(i)
                        filled += 1
                        if s < minScore {
                            minScore = s
                            minIndex = filled - 1
                        }
                        if filled == k {
                            // establish current min across the initial window
                            minIndex = 0
                            minScore = topScores[0]
                            if k > 1 {
                                for j in 1..<k {
                                    if topScores[j] < minScore {
                                        minScore = topScores[j]
                                        minIndex = j
                                    }
                                }
                            }
                        }
                    } else if s > minScore {
                        topScores[minIndex] = s
                        topIds[minIndex] = i
                        // recompute current min
                        minIndex = 0
                        minScore = topScores[0]
                        if k > 1 {
                            for j in 1..<k {
                                if topScores[j] < minScore {
                                    minScore = topScores[j]
                                    minIndex = j
                                }
                            }
                        }
                    }
                }

                let count = filled
                // 2) Apply repetition penalty on the candidate set (logit space).
                if repetitionPenalty > 1.0 && !repSet.isEmpty {
                    for i in 0..<count {
                        if repSet.contains(Int32(topIds[i])) {
                            let s = topScores[i]
                            topScores[i] = (s < 0) ? (s * repetitionPenalty) : (s / repetitionPenalty)
                        }
                    }
                }

                // 3) Sort candidates by adjusted logit (desc).
                var order = Array(0..<count)
                order.sort { topScores[$0] > topScores[$1] }

                // 4) Temperature + softmax over candidates, then apply top-P truncation.
                var maxAdj = -Float.infinity
                var adj = [Float](repeating: 0, count: count)
                for oi in order {
                    let v0 = topScores[oi] / t
                    adj[oi] = v0
                    if v0 > maxAdj { maxAdj = v0 }
                }

                var expVals = [Float](repeating: 0, count: count)
                var expSum: Float = 0
                for oi in order {
                    let e = expf(adj[oi] - maxAdj)
                    expVals[oi] = e
                    expSum += e
                }

                var keptIdx: [Int] = []
                var keptProb: [Float] = []
                keptIdx.reserveCapacity(count)
                keptProb.reserveCapacity(count)

                var cum: Float = 0
                let pCut = min(max(0.0, topP), 1.0)
                for oi in order {
                    let p = expVals[oi] / max(1e-20, expSum)
                    cum += p
                    keptIdx.append(oi)
                    keptProb.append(p)
                    if cum >= pCut { break }
                }

                if temperature <= 0.01 {
                    // Greedy within candidates
                    let best = order.first ?? 0
                    nextToken = llama_token(topIds[best])
                } else {
                    // Sample within the kept set
                    let total = keptProb.reduce(0, +)
                    let r = Float.random(in: 0..<max(total, 1e-6))
                    var acc: Float = 0
                    var chosenLocal = keptIdx.last ?? 0
                    for j in 0..<keptIdx.count {
                        acc += keptProb[j]
                        if acc >= r {
                            chosenLocal = keptIdx[j]
                            break
                        }
                    }
                    nextToken = llama_token(topIds[chosenLocal])
                }

                // 5) Track repetition history
                if ln > 0 {
                    lastTokens.append(nextToken)
                    if lastTokens.count > ln {
                        lastTokens.removeFirst(lastTokens.count - ln)
                    }
                }
            }

            if nextToken == llama_vocab_eos(v) { break }

            // token -> text piece
            var buffer = [CChar](repeating: 0, count: 256)
            let length = llama_token_to_piece(
                v,
                nextToken,
                &buffer,
                Int32(buffer.count),
                0,
                false
            )
            if length > 0 {
                output += String(cString: buffer)
            }

            // Decode next token
            batch.n_tokens = 1
            batch.token[0] = nextToken

            // llama_pos is Int32
            batch.pos[0] = nCur

            batch.n_seq_id[0] = 1
            if let seq_ids = batch.seq_id, let seq0 = seq_ids[0] {
                seq0[0] = 0
            }
            batch.logits[0] = 1

            guard llama_decode(ctx, batch) == 0 else {
                throw EngineError.decodeFailed("generation")
            }

            nCur += 1
        }

        return output.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Special/control token helpers (fast-mode only)

    // Heuristic: treat tokens whose piece looks like "<|...|>" as control/special.
    // Allow known end-of-generation tokens to pass (we want to be able to stop).
    private func isSpecialControlToken(_ v: OpaquePointer, _ tok: llama_token) -> Bool {
        var buf = [CChar](repeating: 0, count: 64)
        let n = llama_token_to_piece(v, tok, &buf, Int32(buf.count), 0, true) // allow special text
        if n <= 0 { return false }
        let s = String(cString: buf)
        return s.hasPrefix("<|") && s.hasSuffix("|>")
    }

    private func isEogLikeToken(_ v: OpaquePointer, _ tok: llama_token, eosFallback: llama_token) -> Bool {
        // Consider EOS/EOT/EOM as EOG tokens.
        if tok == eosFallback { return true }
        var buf = [CChar](repeating: 0, count: 64)
        let n = llama_token_to_piece(v, tok, &buf, Int32(buf.count), 0, true)
        if n <= 0 { return false }
        let s = String(cString: buf)
        return s == "<|end_of_text|>" || s == "<|eot_id|>" || s == "<|eom_id|>"
    }
}

