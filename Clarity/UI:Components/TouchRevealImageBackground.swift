import SwiftUI
import UIKit

struct TouchRevealImageBackground: View {
    let baseImageName: String
    let revealImageName: String

    var baseOpacity: Double = 0.30
    var animationScaleMin: CGFloat = 1.00
    var animationScaleMax: CGFloat = 1.04
    var offsetStart: CGSize = CGSize(width: 10, height: 98)
    var offsetEnd: CGSize = CGSize(width: -10, height: 82)
    var revealSize: CGFloat = 360
    var useSystemBackgroundOverlayOnBase: Bool = false
    var mirroredX: Bool = false
    var contentMode: SwiftUI.ContentMode = .fill

    @State private var animate = false
    @State private var revealPoint: CGPoint? = nil
    @State private var revealAmount: CGFloat = 0

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                backgroundImage(
                    named: baseImageName,
                    in: proxy,
                    opacity: baseOpacity,
                    isBaseLayer: true
                )

                if let revealPoint {
                    backgroundImage(
                        named: revealImageName,
                        in: proxy,
                        opacity: 1.0,
                        isBaseLayer: false
                    )
                    .opacity(revealAmount)
                    .mask {
                        ZStack {
                            Color.clear

                            Circle()
                                .fill(
                                    RadialGradient(
                                        stops: [
                                            .init(color: .white.opacity(1.0), location: 0.00),
                                            .init(color: .white.opacity(0.96), location: 0.18),
                                            .init(color: .white.opacity(0.78), location: 0.36),
                                            .init(color: .white.opacity(0.40), location: 0.62),
                                            .init(color: .white.opacity(0.12), location: 0.82),
                                            .init(color: .clear, location: 1.00)
                                        ],
                                        center: .center,
                                        startRadius: 0,
                                        endRadius: revealSize * (0.48 + (revealAmount * 0.12))
                                    )
                                )
                                .frame(
                                    width: revealSize * (0.96 + revealAmount * 0.08),
                                    height: revealSize * (0.96 + revealAmount * 0.08)
                                )
                                .position(revealPoint)
                                .blur(radius: 26)
                        }
                        .compositingGroup()
                    }
                    .overlay {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        Color.white.opacity(0.10),
                                        Color.cyan.opacity(0.05),
                                        Color.clear
                                    ],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: revealSize * 0.34
                                )
                            )
                            .frame(width: revealSize * 0.72, height: revealSize * 0.72)
                            .position(revealPoint)
                            .opacity(revealAmount * 0.55)
                            .blur(radius: 20)
                    }
                }
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .local)
                    .onChanged { value in
                        revealPoint = value.location
                        withAnimation(.easeOut(duration: 0.14)) {
                            revealAmount = 1
                        }
                    }
                    .onEnded { _ in
                        withAnimation(.easeOut(duration: 0.85)) {
                            revealAmount = 0
                        }

                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.90) {
                            if revealAmount == 0 {
                                revealPoint = nil
                            }
                        }
                    }
            )
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private func backgroundImage(
        named name: String,
        in proxy: GeometryProxy,
        opacity: Double,
        isBaseLayer: Bool
    ) -> some View {
        if UIImage(named: name) != nil {
            imageView(named: name, in: proxy)
                .scaleEffect(animate ? animationScaleMax : animationScaleMin)
                .scaleEffect(x: mirroredX ? -1 : 1, y: 1)
                .offset(
                    x: animate ? offsetEnd.width : offsetStart.width,
                    y: animate ? offsetEnd.height : offsetStart.height
                )
                .overlay {
                    if isBaseLayer && useSystemBackgroundOverlayOnBase {
                        LinearGradient(
                            colors: [
                                Color(.systemBackground).opacity(0.18),
                                Color(.systemBackground).opacity(0.04),
                                Color(.systemBackground).opacity(0.20)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    } else {
                        LinearGradient(
                            colors: [Color.clear, Color.clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    }
                }
                .opacity(opacity)
                .ignoresSafeArea()
                .onAppear { animate = true }
                .animation(
                    .easeInOut(duration: 16).repeatForever(autoreverses: true),
                    value: animate
                )
        }
    }

    @ViewBuilder
    private func imageView(named name: String, in proxy: GeometryProxy) -> some View {
        let image = Image(name).resizable()

        if contentMode == .fill {
            image
                .scaledToFill()
                .frame(width: proxy.size.width, height: proxy.size.height)
        } else {
            image
                .scaledToFit()
                .frame(maxWidth: .infinity)
                .frame(maxHeight: .infinity, alignment: .bottom)
        }
    }
}
