import SwiftUI
import HealthKit

struct ExploreView: View {
    private let guidanceGreen = Color(red: 0.22, green: 0.54, blue: 0.34)
    private let focusBlue = Color(red: 0.24, green: 0.46, blue: 0.90)
    private let healthRose = Color(red: 0.90, green: 0.31, blue: 0.47)
    private let textsBurgundy = Color(red: 0.55, green: 0.24, blue: 0.29)
    private let calendarAmber = Color(red: 0.82, green: 0.58, blue: 0.22)
    private let pilgrimageSlate = Color(red: 0.32, green: 0.42, blue: 0.52)
    private let offeringInk = Color(red: 0.13, green: 0.13, blue: 0.14)
    private let gridColumns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        GeometryReader { geo in
            let isLandscape = geo.size.width > geo.size.height
            let horizontalPadding: CGFloat = 32
            let interItemSpacing: CGFloat = 12
            let rowSpacing: CGFloat = isLandscape ? 18 : 16
            let maxContentWidth: CGFloat = isLandscape ? 560 : 430
            let contentWidth = min(max(0, geo.size.width - horizontalPadding), maxContentWidth)
            let tileWidth = max(0, (contentWidth - interItemSpacing) / 2)
            let standardTileHeight = min(
                isLandscape ? 144 : 126,
                max(108, floor(tileWidth * (isLandscape ? 0.54 : 0.62)))
            )

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    LazyVGrid(columns: gridColumns, spacing: rowSpacing) {
                        NavigationLink {
                            FocusSoundsHubView()
                        } label: {
                            ExploreFeatureTile(
                                title: "Sounds",
                                subtitle: "Songs, tones, and soundscapes",
                                fill: focusBlue,
                                backgroundAssetName: "buttonaudio",
                                tileHeight: standardTileHeight
                            )
                        }
                        .buttonStyle(.plain)

                        NavigationLink {
                            TextsView()
                        } label: {
                            ExploreFeatureTile(
                                title: "Texts",
                                subtitle: "Sutras, prayers, and recitations",
                                fill: textsBurgundy,
                                backgroundAssetName: "buttontext",
                                tileHeight: standardTileHeight
                            )
                        }
                        .buttonStyle(.plain)

                        NavigationLink {
                            TeachingsAudioView()
                        } label: {
                            ExploreFeatureTile(
                                title: "Teachings",
                                subtitle: "Audio teachings with a swipeable player card.",
                                fill: textsBurgundy,
                                backgroundAssetName: "buttonteaching",
                                tileHeight: standardTileHeight
                            )
                        }
                        .buttonStyle(.plain)

                        NavigationLink {
                            AppleHealthExploreView()
                        } label: {
                            ExploreFeatureTile(
                                title: "Health",
                                subtitle: "Sleep, heart, steps, and mindful minutes",
                                fill: healthRose,
                                backgroundAssetName: "buttonapplehealth",
                                tileHeight: standardTileHeight
                            )
                        }
                        .buttonStyle(.plain)

                        NavigationLink {
                            GuidanceHubView()
                        } label: {
                            ExploreFeatureTile(
                                title: "Guidance",
                                subtitle: "Book a one-to-one session",
                                fill: guidanceGreen,
                                backgroundAssetName: "buttonguidance",
                                tileHeight: standardTileHeight
                            )
                        }
                        .buttonStyle(.plain)

                        NavigationLink {
                            CalendarView()
                        } label: {
                            ExploreFeatureTile(
                                title: "Calendar",
                                subtitle: "Lunar dates, observances, and sacred days",
                                fill: calendarAmber,
                                backgroundAssetName: "buttoncalender",
                                tileHeight: standardTileHeight
                            )
                        }
                        .buttonStyle(.plain)

                        NavigationLink {
                            PilgrimageView()
                        } label: {
                            ExploreFeatureTile(
                                title: "Pilgrimage",
                                subtitle: "Places, routes, and future journeys",
                                fill: pilgrimageSlate,
                                backgroundAssetName: "buttonpilgrimage",
                                tileHeight: standardTileHeight
                            )
                        }
                        .buttonStyle(.plain)

                        NavigationLink {
                            LightOfferingView()
                        } label: {
                        ExploreFeatureTile(
                            title: "Virtual Offering",
                            subtitle: "A simple butterlamp practice space",
                            fill: offeringInk,
                            backgroundAssetName: "buttonvoffering",
                            tileHeight: standardTileHeight
                            )
                        }
                        .buttonStyle(.plain)
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Coming Soon")
                            .font(.headline)

                        LazyVGrid(columns: gridColumns, spacing: rowSpacing) {
                            ExplorePlainLink(
                                title: "Podcast",
                                subtitle: "Talks, conversations, and reflective audio will appear here.",
                                systemImage: "mic.circle",
                                backgroundAssetName: "buttonpodcast",
                                tileHeight: standardTileHeight
                            ) {
                                ExplorePlaceholderView(
                                    title: "Podcast",
                                    subtitle: "Talks, conversations, and reflective audio will appear here."
                                )
                            }

                            ExplorePlainLink(
                                title: "Video",
                                subtitle: "Selected video teachings and visual guidance will appear here.",
                                systemImage: "play.rectangle",
                                backgroundAssetName: "buttonvideo",
                                tileHeight: standardTileHeight
                            ) {
                                ExplorePlaceholderView(
                                    title: "Videos",
                                    subtitle: "Selected video teachings and visual guidance will appear here."
                                )
                            }

                            ExplorePlainLink(
                                title: "Courses",
                                subtitle: "Longer guided study journeys will appear here.",
                                systemImage: "square.stack.3d.up",
                                backgroundAssetName: "buttonspare",
                                tileHeight: standardTileHeight
                            ) {
                                ExplorePlaceholderView(
                                    title: "Courses",
                                    subtitle: "Longer guided study journeys and structured courses will appear here."
                                )
                            }

                            ExplorePlainLink(
                                title: "Shop",
                                subtitle: "Future books, practice items, and selected merchandise may appear here.",
                                systemImage: "bag",
                                backgroundAssetName: "buttonshop",
                                tileHeight: standardTileHeight
                            ) {
                                ExplorePlaceholderView(
                                    title: "Shop",
                                    subtitle: "Future books, practice items, and selected merchandise may appear here."
                                )
                            }

                            ExplorePlainLink(
                                title: "Offering",
                                subtitle: "Support places of practice, learning, and preservation",
                                systemImage: "seal.fill",
                                backgroundAssetName: "buttonoffring",
                                tileHeight: standardTileHeight
                            ) {
                                ExplorePlaceholderView(
                                    title: "Make an Offering",
                                    subtitle: "A future space for supporting monasteries, nunneries, universities, and authentic practice communities."
                                )
                            }
                        }
                    }
                }
                .padding(16)
                .padding(.bottom, 104)
                .frame(maxWidth: contentWidth, alignment: .topLeading)
                .frame(maxWidth: .infinity, alignment: .top)
            }
        }
        .background {
            ZStack {
                Color(.systemGroupedBackground)
                ExploreBackgroundRocksView()
            }
            .ignoresSafeArea()
        }
        .navigationTitle("Explore")
        .navigationBarTitleDisplayMode(.inline)
    }
}
private struct AppleHealthExploreView: View {
    @StateObject private var healthKit = HealthKitManager()
    @State private var showManageAccessAlert = false

    private let healthRose = Color(red: 0.82, green: 0.23, blue: 0.36)

    private var isConnected: Bool {
        healthKit.mindfulShareAuthorizationStatus == .sharingAuthorized
    }


    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 14) {
                    HStack(spacing: 12) {
                        Image(systemName: "heart.text.square.fill")
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 54, height: 54)
                            .background(healthRose)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Apple Health")
                                .font(.title3.weight(.semibold))
                            
                            Text(isConnected ? "Connected" : "Optional health context for Clarity")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                    }
                    
                    Text("Connect Apple Health to help Clarity notice patterns around sleep, heart rhythm, daily movement, and mindful time alongside your reflections.")
                        .foregroundStyle(.secondary)
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("What Clarity can use")
                        .font(.headline)
                    
                    AppleHealthBulletRow(
                        systemImage: "bed.double.fill",
                        title: "Sleep",
                        subtitle: "Spot possible links between rest and reflective tone, friction, or ease."
                    )
                    
                    AppleHealthBulletRow(
                        systemImage: "heart.fill",
                        title: "Heart rhythm",
                        subtitle: "Use heart-rate patterns as gentle context, not diagnosis."
                    )
                    
                    AppleHealthBulletRow(
                        systemImage: "figure.walk",
                        title: "Steps and movement",
                        subtitle: "Notice whether steadier days and more movement shift your overall pattern."
                    )
                    
                    AppleHealthBulletRow(
                        systemImage: "brain.head.profile",
                        title: "Mindful minutes",
                        subtitle: "Read mindful sessions and save completed Meditation Zone sessions back to Apple Health."
                    )
                }
                .padding(16)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                
                VStack(alignment: .leading, spacing: 0) {
                    Button {
                        if isConnected {
                            showManageAccessAlert = true
                        } else {
                            Task {
                                await healthKit.requestAuthorization()
                                healthKit.refreshAuthorizationState()
                            }
                        }
                    } label: {
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text("Connect Apple Health")
                                    .foregroundStyle(.primary)
                                
                                Text(
                                    isConnected
                                    ? "Apple Health access has been granted."
                                    : "Request access to sleep, heart rate, steps, and mindful sessions."
                                )
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: isConnected ? "checkmark.circle.fill" : "chevron.right")
                                .font(.headline)
                                .foregroundStyle(isConnected ? .green : .secondary)
                        }
                        .contentShape(Rectangle())
                        .padding(.vertical, 14)
                    }
                    .buttonStyle(.plain)
                    .disabled(healthKit.isBusy)
                    
                    Divider()
                    
                    Toggle(isOn: $healthKit.writeMindfulSessionsEnabled) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Save Meditation Zone sessions to Apple Health")
                            Text("Completed Meditation Zone sessions can be written as mindful minutes.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .disabled(!isConnected || healthKit.isBusy)
                    .padding(.vertical, 14)
                }
                .padding(.horizontal, 16)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                
                if let errorMessage = healthKit.lastErrorMessage, !errorMessage.isEmpty {
                    VStack(alignment: .leading, spacing: 0) {
                        Button {
                            if isConnected {
                                showManageAccessAlert = true
                            } else {
                                Task {
                                    await healthKit.requestAuthorization()
                                    healthKit.refreshAuthorizationState()
                                }
                            }
                        } label: {
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text("Connect Apple Health")
                                        .foregroundStyle(.primary)
                                    
                                    Text(
                                        isConnected
                                        ? "Apple Health access has been granted."
                                        : "Request access to sleep, heart rate, steps, and mindful sessions."
                                    )
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: isConnected ? "checkmark.circle.fill" : "chevron.right")
                                    .font(.headline)
                                    .foregroundStyle(isConnected ? .green : .secondary)
                            }
                            .contentShape(Rectangle())
                            .padding(.vertical, 14)
                        }
                        .buttonStyle(.plain)
                        .disabled(healthKit.isBusy)
                        
                        Divider()
                        
                        Toggle(isOn: $healthKit.writeMindfulSessionsEnabled) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text("Save Meditation Zone sessions to Apple Health")
                                Text("Completed Meditation Zone sessions can be written as mindful minutes.")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .disabled(!isConnected || healthKit.isBusy)
                        .padding(.vertical, 14)
                    }
                    .padding(.horizontal, 16)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("Privacy")
                        .font(.headline)
                    
                    Text("Health data is sensitive. Clarity should keep raw Apple Health data on device, ask only for the types it genuinely uses, and make read and write behaviour clear before permission is requested.")
                        .foregroundStyle(.secondary)
                    
                    Text("For now, only completed Meditation Zone sessions should count as mindful minutes.")
                        .font(.footnote)
                        .foregroundStyle(.tertiary)
                }
                .padding(16)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("Apple Health")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            healthKit.refreshAuthorizationState()
        }
        .alert("Manage Apple Health access", isPresented: $showManageAccessAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("To remove access later, change Clarity’s permissions in the Health app or Settings.")
        }
    }
}

private struct AppleHealthBulletRow: View {
    let systemImage: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: systemImage)
                .font(.headline)
                .frame(width: 22)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.weight(.semibold))

                Text(subtitle)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
    }
}

private struct ExploreTileArtworkAdjustment {
    let xScale: CGFloat
    let yScale: CGFloat
    let xOffset: CGFloat
    let yOffset: CGFloat

    static func forAsset(_ name: String) -> ExploreTileArtworkAdjustment {
        switch name {
        case "buttonguidance":
            // This source image is wider than the rest of the Explore button set,
            // so it needs a stronger horizontal crop than vertical crop.
            return .init(xScale: 1.28, yScale: 1.05, xOffset: 0, yOffset: 0)
        case "buttonspare":
            // Courses uses the same extra-wide composition and needs the same normalization.
            return .init(xScale: 1.10, yScale: 1.03, xOffset: 0, yOffset: 0)
        default:
            return .init(xScale: 1.0, yScale: 1.0, xOffset: 0, yOffset: 0)
        }
    }
}

private struct ExploreFeatureTile: View {
    let title: String
    let subtitle: String
    let fill: Color
    let backgroundAssetName: String?
    let tileHeight: CGFloat

    init(
        title: String,
        subtitle: String,
        fill: Color,
        backgroundAssetName: String? = nil,
        tileHeight: CGFloat = 126
    ) {
        self.title = title
        self.subtitle = subtitle
        self.fill = fill
        self.backgroundAssetName = backgroundAssetName
        self.tileHeight = tileHeight
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                Spacer(minLength: 0)

                Image(systemName: "arrow.up.right")
                    .font(.footnote.weight(.bold))
                    .foregroundStyle(Color.white.opacity(0.88))
                    .padding(.top, 2)
            }

            if backgroundAssetName == nil {
                VStack(alignment: .leading, spacing: 5) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(subtitle)
                        .font(.footnote)
                        .foregroundStyle(Color.white.opacity(0.86))
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: tileHeight, maxHeight: tileHeight, alignment: .topLeading)
        .foregroundStyle(Color.white)
        .background {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(fill.opacity(0.92))
                .overlay {
                    if let backgroundAssetName {
                        let artworkAdjustment = ExploreTileArtworkAdjustment.forAsset(backgroundAssetName)
                        Image(backgroundAssetName)
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .scaleEffect(
                                x: artworkAdjustment.xScale,
                                y: artworkAdjustment.yScale
                            )
                            .offset(
                                x: artworkAdjustment.xOffset,
                                y: artworkAdjustment.yOffset
                            )
                            .clipped()
                            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                    } else {
                        LinearGradient(
                            colors: [
                                fill.opacity(0.98),
                                fill.opacity(0.82)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                    }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.30),
                                    Color.clear,
                                    Color.black.opacity(0.06)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(alignment: .top) {
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.26),
                                            Color.white.opacity(0.06),
                                            Color.clear
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .frame(height: 54)
                                .padding(.horizontal, 10)
                                .padding(.top, 8)
                                .blur(radius: 0.5)
                        }
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.black.opacity(backgroundAssetName == nil ? 0.0 : 0.05),
                                    Color.black.opacity(backgroundAssetName == nil ? 0.0 : 0.24)
                                ],
                                startPoint: .center,
                                endPoint: .bottom
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                )
        }
        .overlay(alignment: .bottomLeading) {
            if backgroundAssetName != nil {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 14)
                    .shadow(color: .black.opacity(0.28), radius: 6, x: 0, y: 2)
            }
        }
        .overlay {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(Color.white.opacity(0.18), lineWidth: 1)
        }
        .shadow(color: Color.black.opacity(0.025), radius: 2, x: 0, y: 1)
        .accessibilityElement(children: .combine)
    }
}

private struct ExplorePlainLink<Destination: View>: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let backgroundAssetName: String?
    let tileHeight: CGFloat
    @ViewBuilder let destination: () -> Destination

    private let comingSoonBlue = Color(red: 0.16, green: 0.36, blue: 0.78)

    init(
        title: String,
        subtitle: String,
        systemImage: String,
        backgroundAssetName: String? = nil,
        tileHeight: CGFloat = 126,
        @ViewBuilder destination: @escaping () -> Destination
    ) {
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
        self.backgroundAssetName = backgroundAssetName
        self.tileHeight = tileHeight
        self.destination = destination
    }

    var body: some View {
        NavigationLink {
            destination()
        } label: {
            if let backgroundAssetName {
                let artworkAdjustment = ExploreTileArtworkAdjustment.forAsset(backgroundAssetName)
                ZStack(alignment: .bottomLeading) {
                    Image(backgroundAssetName)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .scaleEffect(
                            x: artworkAdjustment.xScale,
                            y: artworkAdjustment.yScale
                        )
                        .offset(
                            x: artworkAdjustment.xOffset,
                            y: artworkAdjustment.yOffset
                        )
                        .clipped()
                        .overlay {
                            LinearGradient(
                                colors: [
                                    Color.black.opacity(0.02),
                                    Color.black.opacity(0.28)
                                ],
                                startPoint: .center,
                                endPoint: .bottom
                            )
                        }

                    HStack(alignment: .top) {
                        Spacer()

                        Image(systemName: "arrow.up.right")
                            .font(.footnote.weight(.bold))
                            .foregroundStyle(Color.white.opacity(0.88))
                            .padding(.top, 16)
                            .padding(.trailing, 16)
                    }

                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 14)
                        .shadow(color: .black.opacity(0.28), radius: 6, x: 0, y: 2)
                }
                .frame(maxWidth: .infinity, minHeight: tileHeight, maxHeight: tileHeight)
                .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .stroke(Color.white.opacity(0.18), lineWidth: 1)
                }
                .shadow(color: Color.black.opacity(0.02), radius: 2, x: 0, y: 1)
            } else {
                HStack(spacing: 12) {
                    Image(systemName: systemImage)
                        .font(.title3)
                        .foregroundStyle(comingSoonBlue)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .foregroundStyle(.primary)

                        Text(subtitle)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(comingSoonBlue.opacity(0.75))
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 2)
            }
        }
        .buttonStyle(.plain)
    }
}

private struct ExplorePlaceholderView: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.title3.weight(.semibold))

            Text("Coming soon")
                .font(.headline)
                .foregroundStyle(.secondary)

            Text(subtitle)
                .foregroundStyle(.secondary)

            Spacer()
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Explore background rocks

private struct ExploreBackgroundRocksView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var scale: CGFloat = ExploreBackgroundRocksStyle.startScale
    @State private var hasStartedZoom = false

    var body: some View {
        GeometryReader { geo in
            Image(ExploreBackgroundRocksStyle.assetName)
                .resizable()
                .scaledToFill()
                .frame(width: geo.size.width, height: geo.size.height)
                .position(x: geo.size.width / 2, y: geo.size.height / 2)
                .scaleEffect(scale, anchor: .center)
                .opacity(ExploreBackgroundRocksStyle.baseOpacity)
                .clipped()
                .allowsHitTesting(false)
                .onAppear {
                    guard hasStartedZoom == false else { return }
                    hasStartedZoom = true
                    scale = ExploreBackgroundRocksStyle.startScale
                    guard reduceMotion == false else { return }
                    withAnimation(.easeOut(duration: ExploreBackgroundRocksStyle.zoomDuration)) {
                        scale = ExploreBackgroundRocksStyle.endScale
                    }
                }
        }
    }
}

private enum ExploreBackgroundRocksStyle {
    static let assetName = "rocks"         // asset name
    static let baseOpacity: Double = 0.10  // opacity
    static let startScale: CGFloat = 1.00  // start scale
    static let endScale: CGFloat = 1.22    // end scale
    static let zoomDuration: Double = 60   // slow one-shot zoom
}
