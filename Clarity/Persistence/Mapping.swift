import Foundation

// MARK: - TurnEntity <-> Domain Turn

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

            // Tool outputs
            reflectionText: reflectionText,

            reflectText: reflectText,
            reflectPromptVersion: reflectPromptVersion,
            reflectUpdatedAt: reflectUpdatedAt,

            perspectiveText: perspectiveText,
            perspectivePromptVersion: perspectivePromptVersion,
            perspectiveUpdatedAt: perspectiveUpdatedAt,

            optionsText: optionsText,
            optionsPromptVersion: optionsPromptVersion,
            optionsUpdatedAt: optionsUpdatedAt,

            questionsText: questionsText,
            questionsPromptVersion: questionsPromptVersion,
            questionsUpdatedAt: questionsUpdatedAt,

            talkThreadJSON: talkThreadJSON,
            talkLastResponseID: talkLastResponseID,
            talkPromptVersion: talkPromptVersion,
            talkUpdatedAt: talkUpdatedAt,

            // WAL
            walJSON: walJSON,
            walUpdatedAt: walUpdatedAt,
            walVersion: walVersion,

            // Redaction / state / tooling
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

            error: (errorDomain != nil && errorCode != nil)
                ? TurnError(
                    domain: errorDomain ?? "unknown",
                    code: errorCode ?? -1,
                    userFacingKey: userFacingErrorKey,
                    debugMessage: errorDebugMessage
                )
                : nil
        )
    }

    func apply(domain t: Turn) {
        // Core metadata
        sourceRaw = t.source.rawValue
        recordedAt = t.recordedAt
        endedAt = t.endedAt
        durationSeconds = t.durationSeconds
        sourceOriginalDate = t.sourceOriginalDate
        captureContextRaw = t.captureContext.rawValue

        // Title
        title = t.title

        // Audio
        audioPath = t.audioPath
        audioBytes = t.audioBytes ?? 0

        // Transcript
        transcriptRaw = t.transcriptRaw
        transcriptRedactedActive = t.transcriptRedactedActive

        // Tool outputs (local)
        reflectionText = t.reflectionText

        reflectText = t.reflectText
        reflectPromptVersion = t.reflectPromptVersion
        reflectUpdatedAt = t.reflectUpdatedAt

        perspectiveText = t.perspectiveText
        perspectivePromptVersion = t.perspectivePromptVersion
        perspectiveUpdatedAt = t.perspectiveUpdatedAt

        optionsText = t.optionsText
        optionsPromptVersion = t.optionsPromptVersion
        optionsUpdatedAt = t.optionsUpdatedAt

        questionsText = t.questionsText
        questionsPromptVersion = t.questionsPromptVersion
        questionsUpdatedAt = t.questionsUpdatedAt

        talkThreadJSON = t.talkThreadJSON
        talkLastResponseID = t.talkLastResponseID
        talkPromptVersion = t.talkPromptVersion
        talkUpdatedAt = t.talkUpdatedAt

        // WAL (local)
        walJSON = t.walJSON
        walUpdatedAt = t.walUpdatedAt
        walVersion = t.walVersion

        // Redaction
        redactionVersion = t.redactionVersion
        redactionTimestamp = t.redactionTimestamp
        redactionInputHash = t.redactionInputHash

        // State
        stateRaw = t.state.rawValue

        // Providers / tooling
        transcriptionProviderRaw = t.transcriptionProvider.rawValue
        transcriptionLocale = t.transcriptionLocale

        reflectProviderRaw = t.reflectProvider.rawValue
        promptVersion = t.promptVersion
        toolchainVersion = t.toolchainVersion
        capsuleSnapshotHash = t.capsuleSnapshotHash

        // Processing lifecycle
        processingStartedAt = t.processingStartedAt
        processingFinishedAt = t.processingFinishedAt

        // Error
        errorDomain = t.error?.domain
        errorCode = t.error?.code
        userFacingErrorKey = t.error?.userFacingKey
        errorDebugMessage = t.error?.debugMessage
    }
}

// MARK: - RedactionRecordEntity -> Domain

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

// MARK: - CapsuleEntity <-> Domain

extension CapsuleEntity {

    @MainActor
    func toDomain() throws -> CapsuleModel {
        let decoder = JSONDecoder()

        let prefs = preferencesJSON.isEmpty
            ? CapsulePreferences()
            : try decoder.decode(CapsulePreferences.self, from: preferencesJSON)

        let learned = learnedJSON.isEmpty
            ? []
            : try decoder.decode([CapsuleTendency].self, from: learnedJSON)

        return CapsuleModel(
            version: version,
            learningEnabled: learningEnabled,
            updatedAt: updatedAt,
            preferences: prefs,
            learnedTendencies: learned
        )
    }

    @MainActor
    func apply(domain c: CapsuleModel) throws {
        let encoder = JSONEncoder()
        version = c.version
        learningEnabled = c.learningEnabled
        updatedAt = c.updatedAt
        preferencesJSON = try encoder.encode(c.preferences)
        learnedJSON = try encoder.encode(c.learnedTendencies)
    }
}

