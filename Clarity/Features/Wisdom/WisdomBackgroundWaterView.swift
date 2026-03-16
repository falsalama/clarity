import SwiftUI

struct WisdomBackgroundWaterView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var scale: CGFloat = WisdomBackgroundStyle.startScale

    var body: some View {
        GeometryReader { geo in
            Image(WisdomBackgroundStyle.assetName)
                .resizable()
                .scaledToFill()
                .frame(width: geo.size.width, height: geo.size.height)
                .position(x: geo.size.width / 2, y: geo.size.height / 2)
                .scaleEffect(scale, anchor: .center)
                .opacity(WisdomBackgroundStyle.baseOpacity)
                .clipped()
                .allowsHitTesting(false)
                .onAppear {
                    scale = WisdomBackgroundStyle.startScale
                    guard reduceMotion == false else { return }
                    withAnimation(.easeOut(duration: WisdomBackgroundStyle.zoomDuration)) {
                        scale = WisdomBackgroundStyle.endScale
                    }
                }
        }
    }
}

private enum WisdomBackgroundStyle {
    static let assetName = "water"
    static let baseOpacity: Double = 0.10
    static let startScale: CGFloat = 1.00
    static let endScale: CGFloat = 1.20
    static let zoomDuration: Double = 50
}
