import Foundation

enum ContemplationProviderError: Error, Equatable {
    case unavailable(String)
}

protocol ContemplationProvider {
    func generate(_ request: ContemplationRequest) async throws -> ContemplationResponse
}

final class CloudTapProvider: ContemplationProvider {
    private let service: CloudTapService

    init(service: CloudTapService) {
        self.service = service
    }

    func generate(_ request: ContemplationRequest) async throws -> ContemplationResponse {
        switch request.mode {
        case .reflect, .perspective, .options, .questions:
            let req = CloudTapReflectRequest(
                text: request.text,
                recordedAt: request.recordedAtISO,
                client: "ios",
                appVersion: request.appVersion,
                capsule: request.capsule
            )

            let resp: CloudTapReflectResponse
            switch request.mode {
            case .reflect:
                resp = try await service.reflect(req)
            case .perspective:
                resp = try await service.perspective(req)
            case .options:
                resp = try await service.options(req)
            case .questions:
                resp = try await service.questions(req)
            default:
                fatalError("Unexpected mode")
            }

            return ContemplationResponse(
                text: resp.text,
                promptVersion: resp.prompt_version,
                providerLane: .cloudTap
            )

        case .talkItThrough:
            let talkReq = CloudTapTalkRequest(
                text: request.text,
                recordedAt: request.recordedAtISO,
                client: "ios",
                appVersion: request.appVersion,
                previous_response_id: request.previousResponseID,
                capsule: request.capsule
            )
            let talkResp: CloudTapTalkResponse = try await service.talkItThrough(talkReq)
            return ContemplationResponse(
                text: talkResp.text,
                promptVersion: talkResp.prompt_version,
                providerLane: .cloudTap
            )
        }
    }
}

/// Placeholder provider for Device Tap.
///
/// This lets the UI + settings wiring land cleanly before model integration.
final class DeviceTapPlaceholderProvider: ContemplationProvider {
    func generate(_ request: ContemplationRequest) async throws -> ContemplationResponse {
        throw ContemplationProviderError.unavailable(
            "Device Tap is not configured on this build. Choose Cloud Tap in Settings."
        )
    }
}
