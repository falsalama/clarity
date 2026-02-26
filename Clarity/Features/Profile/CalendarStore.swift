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
    // NEW: optional per-row image key (e.g. "events/penor_rinpoche.jpg" or "ah.jpg")
    let image_key: String?
}

@MainActor
final class CalendarStore: ObservableObject {
    @Published var today: [CalendarObservance] = []
    @Published var upcoming: [CalendarObservance] = []

    private let supabaseURL = "https://yaxpwhimwktqqxyzitao.supabase.co"
    private let anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlheHB3aGltd2t0cXF4eXppdGFvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njk1MDQ3NTIsImV4cCI6MjA4NTA4MDc1Mn0.-WyjZU2okWufyAmWxdC6TRarsopMBUlx6HR5ttlS77M"

    private var feedURL: URL? {
        URL(string:
            "https://yaxpwhimwktqqxyzitao.supabase.co/rest/v1/calendar_observances" +
            "?select=id,date,event_key,title,subtitle,category,importance,practice_angle,tradition_scope,region_scope,image_key" +
            "&enabled=eq.true" +
            "&date=gte.2026-01-01" +
            "&date=lte.2026-12-31" +
            "&order=date.asc"
        )
    }

    func refresh() async {
        guard let url = feedURL else { return }

        var req = URLRequest(url: url)
        req.cachePolicy = .returnCacheDataElseLoad
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        req.setValue(anonKey, forHTTPHeaderField: "apikey")
        req.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")

        do {
            let (data, resp) = try await URLSession.shared.data(for: req)

            if let http = resp as? HTTPURLResponse {
                print("Calendar HTTP:", http.statusCode)
                if http.statusCode >= 400 {
                    print(String(data: data, encoding: .utf8) ?? "no body")
                }
            }

            let decoded = try JSONDecoder().decode([CalendarObservance].self, from: data)

            let todayISO = Self.iso(for: Date())
            self.today = decoded.filter { $0.date == todayISO }
            self.upcoming = decoded
        } catch {
            print("CalendarStore.refresh error:", error)
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
