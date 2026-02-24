import SwiftUI

/// Small counter pill used as the Progress entry point.
///
/// v4:
/// - No portrait in the capsule (portrait lives in the centre of the lotus only)
/// - Split into 3 coloured segments:
///   - Reflect: soft white
///   - View: muted gold
///   - Practice: deep oxblood
struct ProgressCounterCapsule: View {
    let reflectCount: Int
    let focusCount: Int
    let practiceCount: Int

    // Compatibility initializer to satisfy older call sites that still pass `portraitRecipe:`.
    // The portrait is no longer shown in this capsule, so we ignore it.
    init(reflectCount: Int, focusCount: Int, practiceCount: Int, portraitRecipe: PortraitRecipe? = nil) {
        self.reflectCount = reflectCount
        self.focusCount = focusCount
        self.practiceCount = practiceCount
        // portraitRecipe intentionally unused
    }

    var body: some View {
        let stroke = Color.black.opacity(0.16)
        let divider = Color.black.opacity(0.18)

        HStack(spacing: 0) {
            segment(text: format(reflectCount), fill: reflectFill, textColor: .black)
            Rectangle().fill(divider).frame(width: 1)
            segment(text: format(focusCount), fill: focusFill, textColor: .black)
            Rectangle().fill(divider).frame(width: 1)
            segment(text: format(practiceCount), fill: practiceFill, textColor: .white)
        }
        .overlay(Capsule().stroke(stroke, lineWidth: 1))
        .clipShape(Capsule())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Progress counters")
        .accessibilityValue("Reflect \(reflectCount), View \(focusCount), Practice \(practiceCount)")
    }

    private var reflectFill: Color { Color.white.opacity(0.92) }

    private var focusFill: Color {
        Color(red: 0.92, green: 0.80, blue: 0.34).opacity(0.92)
    }

    private var practiceFill: Color {
        Color(red: 0.36, green: 0.10, blue: 0.14).opacity(0.92)
    }

    private func segment(text: String, fill: Color, textColor: Color) -> some View {
        Text(text)
            .font(.footnote.weight(.semibold))
            .foregroundStyle(textColor)
            .frame(minWidth: 28)
            .frame(maxWidth: .infinity)
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
