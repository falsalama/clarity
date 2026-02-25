import SwiftUI

struct CalendarView: View {
    @StateObject private var store = CalendarStore()

    @State private var monthCursor: Date = Date()
    @State private var selectedDate: Date = Date()

    /// Bump this when you overwrite images in Storage to force refresh.
    private let imageVersion = "1"

    private let storageBase =
        "https://yaxpwhimwktqqxyzitao.supabase.co/storage/v1/object/public/calendar_images"

    var body: some View {
        VStack(spacing: 12) {
            header
                .zIndex(10)

            ScrollView {
                VStack(spacing: 12) {
                    MonthGrid(
                        month: monthCursor,
                        selectedDate: selectedDate,
                        hasEventOn: { day in store.hasEvent(on: day) },
                        onTapDay: { day in
                            selectedDate = day
                            monthCursor = day
                        }
                    )
                    .padding(.horizontal, 12)

                    if let url = headerImageURL(for: store.items(on: selectedDate)) {
                        CachedRemoteImage(url: url, contentMode: .fill, maxPixelSize: 1024)
                            .clipped()
                            .frame(maxWidth: .infinity)
                            .frame(height: 190)
                            .background(Color.primary.opacity(0.03))
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                            .padding(.horizontal, 12)
                    }

                    inlineDetails
                        .padding(.horizontal, 12)
                }
                .padding(.bottom, 24)
            }
            .refreshable {
                await store.refresh()
            }
        }
        .navigationTitle("Calendar")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await store.refresh()
            selectedDate = Date()
            monthCursor = Date()
        }
    }

    private var header: some View {
        HStack {
            Button {
                monthCursor = Calendar.current.date(byAdding: .month, value: -1, to: monthCursor) ?? monthCursor
            } label: {
                Image(systemName: "chevron.left")
            }

            Spacer()

            Text(monthTitle(monthCursor))
                .font(.headline)

            Spacer()

            Button {
                monthCursor = Calendar.current.date(byAdding: .month, value: 1, to: monthCursor) ?? monthCursor
            } label: {
                Image(systemName: "chevron.right")
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 8)
    }

    private var inlineDetails: some View {
        let items = store.items(on: selectedDate)

        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(dayTitle(selectedDate))
                    .font(.headline)

                Spacer()

                if Calendar.current.isDateInToday(selectedDate) {
                    Text("Today")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(Color.primary.opacity(0.06))
                        .clipShape(Capsule())
                }
            }

            if items.isEmpty {
                Text("No observances.")
                    .foregroundColor(.secondary)
                    .padding(.vertical, 8)
            } else {
                VStack(spacing: 10) {
                    ForEach(items) { item in
                        ObservanceRow(item: item, imageVersion: imageVersion, storageBase: storageBase)
                    }
                }
            }
        }
        .padding(.top, 2)
    }

    private func headerImageURL(for items: [CalendarObservance]) -> URL? {
        guard let first = items.first else { return nil }
        return resolveImageURL(for: first)
    }

    /// Robust resolver:
    /// - If image_key is "category/foo.jpg" -> use as-is.
    /// - If image_key is "foo.jpg" -> assume it's under category/.
    /// - Else fallback to category/<category>.jpg (category normalised).
    private func resolveImageURL(for item: CalendarObservance) -> URL? {
        let rawKey = item.image_key?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        if !rawKey.isEmpty {
            if rawKey.contains("/") {
                return URL(string: "\(storageBase)/\(rawKey)?v=\(imageVersion)")
            } else {
                return URL(string: "\(storageBase)/category/\(rawKey)?v=\(imageVersion)")
            }
        }

        let cat = item.category.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return URL(string: "\(storageBase)/category/\(cat).jpg?v=\(imageVersion)")
    }

    private func monthTitle(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_GB")
        f.dateFormat = "LLLL yyyy"
        return f.string(from: date)
    }

    private func dayTitle(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_GB")
        f.dateFormat = "EEE d MMM"
        return f.string(from: date)
    }
}

private struct MonthGrid: View {
    let month: Date
    let selectedDate: Date
    let hasEventOn: (Date) -> Bool
    let onTapDay: (Date) -> Void

    private let cols = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)

    var body: some View {
        let days = monthDays(month)

        VStack(spacing: 8) {
            weekdayHeader

            LazyVGrid(columns: cols, spacing: 8) {
                ForEach(days, id: \.self) { day in
                    DayCell(
                        date: day,
                        inSameMonth: Calendar.current.isDate(day, equalTo: month, toGranularity: .month),
                        isSelected: Calendar.current.isDate(day, inSameDayAs: selectedDate),
                        hasEvent: hasEventOn(day),
                        onTap: { onTapDay(day) }
                    )
                }
            }
        }
    }

    private var weekdayHeader: some View {
        let cal = Calendar.current
        let symbols = cal.shortWeekdaySymbols
        let shift = (cal.firstWeekday - 1 + symbols.count) % symbols.count
        let rotated = Array(symbols[shift...] + symbols[..<shift])

        return HStack {
            ForEach(rotated, id: \.self) { s in
                Text(s)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private func monthDays(_ month: Date) -> [Date] {
        let cal = Calendar.current
        let startOfMonth = cal.date(from: cal.dateComponents([.year, .month], from: month))!
        let range = cal.range(of: .day, in: .month, for: startOfMonth)!
        let firstWeekday = cal.component(.weekday, from: startOfMonth)
        let leading = (firstWeekday - cal.firstWeekday + 7) % 7

        var days: [Date] = []

        for i in stride(from: leading, to: 0, by: -1) {
            if let d = cal.date(byAdding: .day, value: -i, to: startOfMonth) { days.append(d) }
        }

        for day in range {
            if let d = cal.date(byAdding: .day, value: day - 1, to: startOfMonth) { days.append(d) }
        }

        while days.count < 42 {
            if let last = days.last, let next = cal.date(byAdding: .day, value: 1, to: last) {
                days.append(next)
            } else { break }
        }

        return days
    }
}

private struct DayCell: View {
    let date: Date
    let inSameMonth: Bool
    let isSelected: Bool
    let hasEvent: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                Text("\(dayNumber)")
                    .font(.subheadline)
                    .foregroundColor(inSameMonth ? .primary : .secondary.opacity(0.5))
                    .frame(maxWidth: .infinity)

                Circle()
                    .fill(hasEvent ? Color.primary.opacity(0.65) : Color.clear)
                    .frame(width: 5, height: 5)
            }
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity, minHeight: 38)
            .contentShape(Rectangle())
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isSelected ? Color.yellow.opacity(0.14) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(isSelected ? Color.yellow.opacity(0.55) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var dayNumber: Int {
        Calendar.current.component(.day, from: date)
    }
}

struct ObservanceRow: View {
    let item: CalendarObservance
    let imageVersion: String
    let storageBase: String

    var body: some View {
        HStack(spacing: 12) {
            CachedRemoteImage(url: imageURL, contentMode: .fill, maxPixelSize: 256)
                .frame(width: 56, height: 56)
                .background(Color.primary.opacity(0.03))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.headline)

                if let subtitle = item.subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Text("\(item.tradition_scope.uppercased()) · \(item.region_scope.uppercased())")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer(minLength: 0)
        }
    }

    private var imageURL: URL? {
        let rawKey = item.image_key?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        if !rawKey.isEmpty {
            if rawKey.contains("/") {
                return URL(string: "\(storageBase)/\(rawKey)?v=\(imageVersion)")
            } else {
                return URL(string: "\(storageBase)/category/\(rawKey)?v=\(imageVersion)")
            }
        }

        let cat = item.category.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return URL(string: "\(storageBase)/category/\(cat).jpg?v=\(imageVersion)")
    }
}
