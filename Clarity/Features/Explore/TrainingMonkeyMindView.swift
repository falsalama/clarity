import SwiftUI

private enum TrainingMonkeyMindPage {
    case image
    case text
}

struct TrainingMonkeyMindView: View {
    @State private var currentPage: TrainingMonkeyMindPage = .image

    private var textPageBackgroundColor: Color {
#if os(iOS)
        Color(uiColor: .systemGroupedBackground)
#else
        Color(NSColor.windowBackgroundColor)
#endif
    }

    var body: some View {
        ZStack {
            Group {
                switch currentPage {
                case .image:
                    TrainingMonkeyMindImagePage {
                        withAnimation(.easeInOut(duration: 0.28)) {
                            currentPage = .text
                        }
                    }
                    .transition(
                        .asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        )
                    )

                case .text:
                    TrainingMonkeyMindTextPage {
                        withAnimation(.easeInOut(duration: 0.28)) {
                            currentPage = .image
                        }
                    }
                    .background(textPageBackgroundColor.ignoresSafeArea())
                    .transition(
                        .asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        )
                    )
                }
            }

            VStack {
                Spacer()
                TrainingMonkeyMindPageDots(currentPage: currentPage)
                    .padding(.bottom, 18)
            }
        }
        .background(
            Group {
                if currentPage == .image {
                    Color.black
                } else {
                    textPageBackgroundColor
                }
            }
            .ignoresSafeArea()
        )
        .navigationTitle("Training the Monkey Mind")
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
    }
}

private struct TrainingMonkeyMindImagePage: View {
    let onAdvance: () -> Void

    @State private var revealPoint: CGPoint? = nil
    @State private var revealAmount: CGFloat = 0

    private let revealSize: CGFloat = 320

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Color.black.ignoresSafeArea()

                monkeyImage(named: "monkeymind", in: proxy)
                    .opacity(0.98)

                if let revealPoint {
                    monkeyImage(named: "monkeymindcol", in: proxy)
                        .opacity(revealAmount * 0.98)
                        .mask {
                            ZStack {
                                Color.clear

                                Circle()
                                    .fill(
                                        RadialGradient(
                                            stops: [
                                                .init(color: .white.opacity(1.0), location: 0.00),
                                                .init(color: .white.opacity(0.93), location: 0.18),
                                                .init(color: .white.opacity(0.74), location: 0.40),
                                                .init(color: .white.opacity(0.34), location: 0.72),
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
                                    .blur(radius: 24)
                            }
                            .compositingGroup()
                        }
                }

                LinearGradient(
                    colors: [
                        Color.black.opacity(0.20),
                        Color.clear,
                        Color.black.opacity(0.18)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                HStack {
                    Spacer()
                    TrainingMonkeyMindArrowButton(
                        systemImage: "chevron.right",
                        action: onAdvance
                    )
                    .padding(.trailing, 18)
                }
            }
            .contentShape(Rectangle())
            .simultaneousGesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .local)
                    .onChanged { value in
                        startReveal(at: value.location)
                    }
                    .onEnded { _ in
                        endReveal(after: 0.84)
                    }
            )
            .simultaneousGesture(
                SpatialTapGesture()
                    .onEnded { value in
                        startReveal(at: value.location)
                        endReveal(after: 0.84)
                    }
            )
        }
        .ignoresSafeArea()
    }

    private func startReveal(at point: CGPoint) {
        revealPoint = point
        withAnimation(.easeOut(duration: 0.14)) {
            revealAmount = 1
        }
    }

    private func endReveal(after delay: Double) {
        withAnimation(.easeOut(duration: 0.78)) {
            revealAmount = 0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            if revealAmount == 0 {
                revealPoint = nil
            }
        }
    }

    @ViewBuilder
    private func monkeyImage(named name: String, in proxy: GeometryProxy) -> some View {
        let overscanWidth = proxy.size.width * 1.08
        let overscanHeight = proxy.size.height * 1.04

#if os(iOS)
        if UIImage(named: name) != nil {
            Image(name)
                .resizable()
                .scaledToFill()
                .frame(width: overscanWidth, height: overscanHeight)
                .clipped()
                .ignoresSafeArea()
        } else {
            Color.black
        }
#else
        Image(name)
            .resizable()
            .scaledToFill()
            .frame(width: overscanWidth, height: overscanHeight)
            .clipped()
            .ignoresSafeArea()
#endif
    }
}

private struct TrainingMonkeyMindTextPage: View {
    let onBack: () -> Void

    var body: some View {
        ZStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    TrainingMonkeyMindCopyCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Training the Monkey Mind")
                                    .font(.title3.weight(.semibold))

                                Text("The monk, the elephant, and the monkey form a map of training the mind.")
                                    .font(.headline)

                            Text("The elephant represents mind itself - at first heavy, dark, and difficult to guide. The monkey represents distraction, restlessness, and the habit of chasing whatever pulls attention away. The monk is steady recollection: the quiet willingness to return again and again. As practice matures, the elephant gradually lightens, the monkey loses its hold, and the path becomes less about struggle and more about growing familiar with ease.")
                                .foregroundStyle(.secondary)

                            Text("This image is not teaching harsh control. It shows that mind can be trained without aggression. At first attention is scattered. Then it is gathered. Then it begins to rest. Along the way, agitation softens, dullness becomes more apparent, and awareness grows steadier, brighter, and more workable. What changes is not that thoughts are violently removed, but that they no longer dominate the whole field.")
                                .foregroundStyle(.secondary)

                            Text("This matters because calm is not the final goal. Shamatha prepares the ground. When the mind is less pulled around by impulse, there is more space, more clarity, and less belief in every passing movement. The point is not to become a perfect meditator. It is to discover that disturbance is not solid, attention can be educated, and openness is already nearer than it seems.")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(16)
                .padding(.top, 16)
                .padding(.bottom, 40)
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }

            HStack {
                TrainingMonkeyMindArrowButton(
                    systemImage: "chevron.left",
                    action: onBack
                )
                .padding(.leading, 18)
                Spacer()
            }
        }
    }
}

private struct TrainingMonkeyMindArrowButton: View {
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 46, height: 46)
                .background(
                    Circle()
                        .fill(Color.black.opacity(0.34))
                )
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.14), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

private struct TrainingMonkeyMindPageDots: View {
    let currentPage: TrainingMonkeyMindPage

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(currentPage == .image ? Color.white.opacity(0.92) : Color.white.opacity(0.28))
                .frame(width: 8, height: 8)

            Circle()
                .fill(currentPage == .text ? Color.white.opacity(0.92) : Color.white.opacity(0.28))
                .frame(width: 8, height: 8)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule(style: .continuous)
                .fill(Color.black.opacity(0.24))
        )
        .overlay(
            Capsule(style: .continuous)
                .stroke(Color.white.opacity(0.10), lineWidth: 1)
        )
    }
}

private struct TrainingMonkeyMindCopyCard<Content: View>: View {
    @ViewBuilder let content: Content

    private var cardBackgroundColor: Color {
#if os(iOS)
        Color(uiColor: .systemBackground)
#else
        Color(NSColor.textBackgroundColor)
#endif
    }

    var body: some View {
        content
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(cardBackgroundColor.opacity(0.94))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(Color.primary.opacity(0.10), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.05), radius: 16, y: 8)
    }
}
