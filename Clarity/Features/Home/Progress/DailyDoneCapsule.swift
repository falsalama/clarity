// Clarity/Features/Progress/DailyDoneCapsule.swift

import SwiftUI

/// Single-pill counter for "daily completion" (1 per day).
struct DailyDoneCapsule: View {
    let count: Int

    var body: some View {
        let stroke = Color.black.opacity(0.16)
        let fill = Color.black.opacity(0.06)

        HStack(spacing: 8) {
            Text("Daily")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)

            Text(format(count))
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(fill)
        .overlay(Capsule().stroke(stroke, lineWidth: 1))
        .clipShape(Capsule())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Daily completions")
        .accessibilityValue("\(max(0, count))")
    }

    private func format(_ value: Int) -> String {
        let v = max(0, value)
        if v >= 1000 { return "999+" }
        return String(v)
    }
}
