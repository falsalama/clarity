// TopCounterBadge.swift

import SwiftUI

/// Single-number badge for the top-right of a tab.
/// Colour is supplied by the caller to match the tab’s identity.
struct TopCounterBadge: View {
    let count: Int
    let fill: Color
    let textColor: Color

    init(count: Int, fill: Color, textColor: Color = .black) {
        self.count = count
        self.fill = fill
        self.textColor = textColor
    }

    var body: some View {
        let shown = max(0, count)

        Text("\(shown)")
            .font(.footnote.weight(.semibold))
            .foregroundStyle(textColor)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(fill)
            .clipShape(Capsule())
            .contentShape(Rectangle())
    }
}
