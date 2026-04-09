import SwiftUI
import HealthKit

struct ExploreView: View {
    private let meditationGold = Color(red: 0.84, green: 0.70, blue: 0.24)
    private let guidanceGreen = Color(red: 0.18, green: 0.46, blue: 0.28)
    private let focusBlue = Color(red: 0.16, green: 0.36, blue: 0.78)
    private let healthRose = Color(red: 0.82, green: 0.23, blue: 0.36)

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                NavigationLink {
                    MeditationZoneView()
                } label: {
                    ExplorePillCTA(
                        title: "Meditation Zone",
                        subtitle: "Timer, posture, shamatha, and recitation",
                        systemImage: "figure.mind.and.body",
                        fill: meditationGold
                    )
                }
                .buttonStyle(.plain)

                NavigationLink {
                    FocusSoundsHubView()
                } label: {
                    ExplorePillCTA(
                        title: "Meditative Sounds",
                        subtitle: "Meditative sounds",
                        systemImage: "waveform",
                        fill: focusBlue
                    )
                }
                .buttonStyle(.plain)

                NavigationLink {
                    AppleHealthExploreView()
                } label: {
                    ExplorePillCTA(
                        title: "Apple Health",
                        subtitle: "Sleep, heart, steps, and mindful minutes",
                        systemImage: "heart.text.square.fill",
                        fill: healthRose
                    )
                }
                .buttonStyle(.plain)

                NavigationLink {
                    GuidanceHubView()
                } label: {
                    ExplorePillCTA(
                        title: "Guidance",
                        subtitle: "Book a one-to-one session",
                        systemImage: "person.2.fill",
                        fill: guidanceGreen
                    )
                }
                .buttonStyle(.plain)

                NavigationLink {
                    TextsView()
                } label: {
                    ExplorePillCTA(
                        title: "Texts",
                        subtitle: "Sutras, prayers, and recitations",
                        systemImage: "book.closed",
                        fill: Color(red: 0.38, green: 0.13, blue: 0.14)
                    )
                }
                .buttonStyle(.plain)

                VStack(alignment: .leading, spacing: 10) {
                    Text("Coming Soon")
                        .font(.headline)

                    ExplorePlainLink(title: "Teachings", subtitle: "Curated teachings and structured learning will appear here.", systemImage: "book.pages") {
                        ExplorePlaceholderView(
                            title: "Teachings",
                            subtitle: "Curated teachings and structured learning will appear here."
                        )
                    }

                    ExplorePlainLink(title: "Podcast", subtitle: "Talks, conversations, and reflective audio will appear here.", systemImage: "mic.circle") {
                        ExplorePlaceholderView(
                            title: "Podcast",
                            subtitle: "Talks, conversations, and reflective audio will appear here."
                        )
                    }

                    ExplorePlainLink(title: "Videos", subtitle: "Selected video teachings and visual guidance will appear here.", systemImage: "play.rectangle") {
                        ExplorePlaceholderView(
                            title: "Videos",
                            subtitle: "Selected video teachings and visual guidance will appear here."
                        )
                    }

                    ExplorePlainLink(title: "Courses", subtitle: "Longer guided pathways and future modules will appear here.", systemImage: "square.stack.3d.up") {
                        ExplorePlaceholderView(
                            title: "Courses",
                            subtitle: "Longer guided pathways and future modules will appear here."
                        )
                    }

                    ExplorePlainLink(title: "Shop", subtitle: "Future books, practice items, and selected merchandise may appear here.", systemImage: "bag") {
                        ExplorePlaceholderView(
                            title: "Shop",
                            subtitle: "Future books, practice items, and selected merchandise may appear here."
                        )
                    }

                    ExplorePlainLink(title: "Make an Offering", subtitle: "Support places of practice, learning, and preservation", systemImage: "seal.fill") {
                        ExplorePlaceholderView(
                            title: "Make an Offering",
                            subtitle: "A future space for supporting monasteries, nunneries, universities, and authentic practice communities."
                        )
                    }
                }
            }
            .padding(16)
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

private struct ExplorePillCTA: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let fill: Color
    var textColor: Color = .white

    // Matches the outer ExploreView .padding(16)
    private let horizontalBleed: CGFloat = 16

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.title3.weight(.semibold))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)

                Text(subtitle)
                    .font(.footnote)
                    .opacity(0.9)
                    .lineLimit(2)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.subheadline.weight(.semibold))
                .opacity(0.85)
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)   // keeps text/icons where they are now
        .foregroundStyle(textColor)
        .background {
            Rectangle()
                .fill(fill)
                .padding(.horizontal, -horizontalBleed) // extends stripe to screen edge
        }
        .overlay {
            Rectangle()
                .stroke(
                    textColor == .white
                        ? Color.white.opacity(0.08)
                        : Color.black.opacity(0.08),
                    lineWidth: 1
                )
                .padding(.horizontal, -horizontalBleed)
        }
        .accessibilityElement(children: .combine)
    }
}

private struct ExplorePlainLink<Destination: View>: View {
    let title: String
    let subtitle: String
    let systemImage: String
    @ViewBuilder let destination: () -> Destination

    private let comingSoonBlue = Color(red: 0.16, green: 0.36, blue: 0.78)

    var body: some View {
        NavigationLink {
            destination()
        } label: {
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
