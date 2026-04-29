import Foundation
import Combine
import Supabase

@MainActor
final class SupabaseAuthStore: ObservableObject {
    enum AccountDeletionError: LocalizedError {
        case unavailable
        case missingSession
        case http(Int, String)
        case network(String)

        var errorDescription: String? {
            switch self {
            case .unavailable:
                return "Cloud account deletion is not configured."
            case .missingSession:
                return "No active cloud account session was found."
            case .http(let status, let body):
                return "Delete failed (\(status)): \(body)"
            case .network(let message):
                return message
            }
        }
    }

    enum State: Equatable {
        case unavailable
        case idle
        case signingIn
        case ready(userID: String)
        case failed(String)
    }

    @Published private(set) var state: State = .idle

    let client: SupabaseClient?

    init() {
        guard
            let supabaseURL = CloudTapConfig.supabaseURL,
            let anonKey = CloudTapConfig.supabaseAnonKey
        else {
            self.client = nil
            clearCachedSession()
            self.state = .unavailable
            return
        }

        self.client = SupabaseClient(
            supabaseURL: supabaseURL,
            supabaseKey: anonKey,
            options: .init(
                auth: .init(
                    autoRefreshToken: true,
                    emitLocalSessionAsInitialSession: true
                )
            )
        )

        if let session = client?.auth.currentSession, !session.isExpired {
            applySession(session)
        } else {
            clearCachedSession()
            self.state = .idle
        }
    }

    var accessToken: String? {
        AppServices.supabaseAccessToken
    }

    func bootstrapAnonymousSessionIfNeeded() async {
        guard let client else {
            clearCachedSession()
            state = .unavailable
            return
        }

        do {
            let session = try await client.auth.session
            if !session.isExpired {
                applySession(session)
                return
            }
        } catch {
            // No valid session yet. Fall through to anonymous sign-in.
        }

        state = .signingIn

        do {
            let session = try await client.auth.signInAnonymously()
            applySession(session)
        } catch {
            clearCachedSession()
            #if DEBUG
            print("Supabase anonymous sign-in failed:", String(describing: error))
            #endif
            state = .failed(String(describing: error))
        }
    }

    func deleteCloudAccountAndData() async throws {
        guard let client else {
            clearCachedSession()
            state = .unavailable
            throw AccountDeletionError.unavailable
        }

        guard let accessToken = AppServices.supabaseAccessToken, !accessToken.isEmpty else {
            throw AccountDeletionError.missingSession
        }

        guard case .available(let cfg) = CloudTapConfig.availability() else {
            throw AccountDeletionError.unavailable
        }

        let url = resolveFunctionURL(base: cfg.baseURL, endpoint: "delete-account")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.timeoutInterval = 30
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        req.setValue(cfg.supabaseAnonKey, forHTTPHeaderField: "apikey")
        req.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        do {
            let (data, response) = try await URLSession.shared.data(for: req)
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0

            guard (200..<300).contains(status) else {
                let body = String(data: data, encoding: .utf8) ?? ""
                throw AccountDeletionError.http(status, body)
            }
        } catch let error as AccountDeletionError {
            throw error
        } catch {
            throw AccountDeletionError.network(String(describing: error))
        }

        try? await client.auth.signOut()
        clearCachedSession()
        state = .idle

        do {
            let session = try await client.auth.signInAnonymously()
            applySession(session)
        } catch {
            // The current cloud account was deleted. If a replacement anonymous
            // session cannot be created immediately, the next app launch will retry.
            clearCachedSession()
            state = .idle
        }
    }

    private func applySession(_ session: Session) {
        let userID = "\(session.user.id)"
        AppServices.supabaseAccessToken = session.accessToken
        AppServices.supabaseUserID = userID

        #if DEBUG
        print(
            "Supabase session ready:",
            "userID=", userID,
            "tokenPrefix=", session.accessToken.prefix(18)
        )
        #endif

        state = .ready(userID: userID)
    }

    private func clearCachedSession() {
        AppServices.supabaseAccessToken = nil
        AppServices.supabaseUserID = nil
    }

    private func resolveFunctionURL(base: URL, endpoint: String) -> URL {
        let last = base.lastPathComponent
        if last.hasPrefix("cloudtap-") {
            return base.deletingLastPathComponent().appendingPathComponent(endpoint)
        }
        return base.appendingPathComponent(endpoint)
    }
}
