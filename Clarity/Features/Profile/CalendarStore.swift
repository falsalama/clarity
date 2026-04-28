import Foundation
import Combine

struct CalendarObservance: Decodable, Identifiable {
    let id: Int
    let date: String
    let event_key: String
    let title: String
    let subtitle: String?
    let category: String
    let importance: Int
    let practice_angle: String?
    let tradition_scope: String
    let region_scope: String
    let image_key: String?
}

@MainActor
final class CalendarStore: ObservableObject {
    @Published var today: [CalendarObservance] = []
    @Published var upcoming: [CalendarObservance] = []

    private var supabaseURL: URL? {
        CloudTapConfig.supabaseURL
    }

    private var anonKey: String? {
        CloudTapConfig.supabaseAnonKey
    }

    private var feedURL: URL? {
        guard let supabaseURL else { return nil }

        let raw =
            supabaseURL.absoluteString +
            "/rest/v1/calendar_observances" +
            "?select=id,date,event_key,title,subtitle,category,importance,practice_angle,tradition_scope,region_scope,image_key" +
            "&enabled=eq.true" +
            "&date=gte.2026-01-01" +
            "&date=lte.2026-12-31" +
            "&order=date.asc"

        return URL(string: raw)
    }

    func refresh() async {
        guard let url = feedURL, let anonKey else {
            today = []
            upcoming = []
            return
        }

        var req = URLRequest(url: url)
        req.cachePolicy = .returnCacheDataElseLoad
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        req.setValue(anonKey, forHTTPHeaderField: "apikey")
        req.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")

        do {
            let (data, resp) = try await URLSession.shared.data(for: req)

            if let http = resp as? HTTPURLResponse {
#if DEBUG
                print("Calendar HTTP:", http.statusCode)
                if http.statusCode >= 400 {
                    print(String(data: data, encoding: .utf8) ?? "no body")
                }
#endif
            }

            let decoded = try JSONDecoder().decode([CalendarObservance].self, from: data)

            let todayISO = Self.iso(for: Date())
            self.today = decoded.filter { $0.date == todayISO }
            self.upcoming = decoded
        } catch {
#if DEBUG
            print("CalendarStore.refresh error:", error)
#endif
            self.today = []
            self.upcoming = []
        }
    }

    func hasEvent(on date: Date) -> Bool {
        let key = Self.iso(for: date)
        return upcoming.contains(where: { $0.date == key })
    }

    func items(on date: Date) -> [CalendarObservance] {
        let key = Self.iso(for: date)
        return upcoming.filter { $0.date == key }
    }

    private static func iso(for date: Date) -> String {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_GB")
        f.timeZone = TimeZone.current
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }
}
