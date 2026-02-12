// AchievementsCounterCapsule.swift

import SwiftUI

/// Small counter pill used as the Achievements entry point.
///
/// v2: split into 3 coloured segments:
/// - Reflect: soft white
/// - Focus: muted gold
/// - Practice: deep oxblood
///
/// Intentionally restrained: three numbers, no labels.
struct AchievementsCounterCapsule: View {
    let reflectCount: Int
    let focusCount: Int
    let practiceCount: Int

    var body: some View {
        let stroke = Color.black.opacity(0.16)
        let divider = Color.black.opacity(0.18)

        HStack(spacing: 0) {
            segment(
                text: format(reflectCount),
                fill: reflectFill,
                textColor: .black
            )

            Rectangle().fill(divider).frame(width: 1)

            segment(
                text: format(focusCount),
                fill: focusFill,
                textColor: .black
            )

            Rectangle().fill(divider).frame(width: 1)

            segment(
                text: format(practiceCount),
                fill: practiceFill,
                textColor: .white
            )
        }
        .overlay(Capsule().stroke(stroke, lineWidth: 1))
        .clipShape(Capsule())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Achievements counters")
        .accessibilityValue("Reflect \(reflectCount), Focus \(focusCount), Practice \(practiceCount)")
    }

    private var reflectFill: Color {
        Color.white.opacity(0.92)
    }

    private var focusFill: Color {
        // Muted gold (kept close to your existing gold, but less loud)
        Color(red: 0.92, green: 0.80, blue: 0.34).opacity(0.92)
    }

    private var practiceFill: Color {
        // Deep maroon / oxblood
        Color(red: 0.36, green: 0.10, blue: 0.14).opacity(0.92)
    }

    private func segment(text: String, fill: Color, textColor: Color) -> some View {
        Text(text)
            .font(.footnote.weight(.semibold))
            .foregroundStyle(textColor)
            .frame(minWidth: 28)
            .frame(maxWidth: .infinity) // equal thirds
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(fill)
            .contentShape(Rectangle())
    }

    private func format(_ value: Int) -> String {
        let v = max(0, value)
        if v >= 1000 { return "999+" }
        return String(v)
    }
}
