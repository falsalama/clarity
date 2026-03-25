import Foundation
import Combine
import Supabase

@MainActor
final class SupabaseAuthStore: ObservableObject {
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
}
