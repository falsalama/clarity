import Foundation

extension TurnEntity {
    func toDomain() -> Turn {
        Turn(
            id: id,
            source: TurnSource(rawValue: sourceRaw) ?? .captured,
            recordedAt: recordedAt,
            endedAt: endedAt,
            durationSeconds: durationSeconds,
            sourceOriginalDate: sourceOriginalDate,
            captureContext: CaptureContext(rawValue: captureContextRaw) ?? .unknown,
            title: title,
            audioPath: audioPath,
            audioBytes: audioBytes,
            transcriptRaw: transcriptRaw,
            transcriptRedactedActive: transcriptRedactedActive,
            redactionVersion: redactionVersion,
            redactionTimestamp: redactionTimestamp,
            redactionInputHash: redactionInputHash,
            state: TurnState(rawValue: stateRaw) ?? .failed,
            transcriptionProvider: TranscriptionProvider(rawValue: transcriptionProviderRaw) ?? .unknown,
            transcriptionLocale: transcriptionLocale,
            reflectProvider: ReflectProvider(rawValue: reflectProviderRaw) ?? .none,
            promptVersion: promptVersion,
            toolchainVersion: toolchainVersion,
            capsuleSnapshotHash: capsuleSnapshotHash,
            processingStartedAt: processingStartedAt,
            processingFinishedAt: processingFinishedAt,
            error: (errorDomain != nil && errorCode != nil) ? TurnError(
                domain: errorDomain ?? "unknown",
                code: errorCode ?? -1,
                userFacingKey: userFacingErrorKey,
                debugMessage: errorDebugMessage
            ) : nil
        )
    }

    func apply(domain t: Turn) {
        sourceRaw = t.source.rawValue
        recordedAt = t.recordedAt
        endedAt = t.endedAt
        durationSeconds = t.durationSeconds
        sourceOriginalDate = t.sourceOriginalDate
        captureContextRaw = t.captureContext.rawValue
        title = t.title
        audioPath = t.audioPath
        audioBytes = t.audioBytes ?? 0
        transcriptRaw = t.transcriptRaw
        transcriptRedactedActive = t.transcriptRedactedActive
        redactionVersion = t.redactionVersion
        redactionTimestamp = t.redactionTimestamp
        redactionInputHash = t.redactionInputHash
        stateRaw = t.state.rawValue
        transcriptionProviderRaw = t.transcriptionProvider.rawValue
        transcriptionLocale = t.transcriptionLocale
        reflectProviderRaw = t.reflectProvider.rawValue
        promptVersion = t.promptVersion
        toolchainVersion = t.toolchainVersion
        capsuleSnapshotHash = t.capsuleSnapshotHash
        processingStartedAt = t.processingStartedAt
        processingFinishedAt = t.processingFinishedAt
        errorDomain = t.error?.domain
        errorCode = t.error?.code
        userFacingErrorKey = t.error?.userFacingKey
        errorDebugMessage = t.error?.debugMessage
    }
}

extension RedactionRecordEntity {
    func toDomain() -> RedactionRecord {
        RedactionRecord(
            id: id,
            turnId: turnId,
            version: version,
            timestamp: timestamp,
            inputHash: inputHash,
            textRedacted: textRedacted
        )
    }
}

extension CapsuleEntity {
    @MainActor func toDomain() throws -> Capsule {
        let decoder = JSONDecoder()

        let prefs = (preferencesJSON.isEmpty) ? CapsulePreferences() :
            (try decoder.decode(CapsulePreferences.self, from: preferencesJSON))

        let learned = (learnedJSON.isEmpty) ? [] :
            (try decoder.decode([CapsuleTendency].self, from: learnedJSON))

        return Capsule(
            version: version,
            learningEnabled: learningEnabled,
            updatedAt: updatedAt,
            preferences: prefs,
            learnedTendencies: learned
        )
    }

    @MainActor func apply(domain c: Capsule) throws {
        let encoder = JSONEncoder()
        version = c.version
        learningEnabled = c.learningEnabled
        updatedAt = c.updatedAt
        preferencesJSON = try encoder.encode(c.preferences)
        learnedJSON = try encoder.encode(c.learnedTendencies)
    }
}

