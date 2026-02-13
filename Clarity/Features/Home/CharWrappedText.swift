import SwiftUI
import UIKit

struct CharWrappedText: UIViewRepresentable {
    let text: String
    let font: UIFont
    let color: UIColor
    let alignment: NSTextAlignment
    let numberOfLines: Int   // pass 0 for unlimited

    func makeUIView(context: Context) -> UILabel {
        let label = UILabel()
        label.numberOfLines = numberOfLines
        label.lineBreakMode = .byCharWrapping
        if #available(iOS 14.0, *) {
            label.lineBreakStrategy = [.standard, .hangulWordPriority, .pushOut]
        }
        label.textAlignment = alignment
        label.textColor = color
        label.backgroundColor = .clear
        label.adjustsFontForContentSizeCategory = true
        label.clipsToBounds = true
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        label.setContentHuggingPriority(.required, for: .vertical)
        return label
    }

    func updateUIView(_ uiView: UILabel, context: Context) {
        uiView.text = text
        uiView.font = font
        uiView.numberOfLines = numberOfLines
    }
}
