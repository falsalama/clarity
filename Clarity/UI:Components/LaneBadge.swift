// LaneBadge.swift
import SwiftUI

struct LaneBadge: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.thinMaterial)
            .clipShape(SwiftUI.Capsule())
            .overlay(
                SwiftUI.Capsule()
                    .strokeBorder(Color.secondary.opacity(0.35), lineWidth: 0.5)
            )
            .accessibilityLabel(text)
    }
}

