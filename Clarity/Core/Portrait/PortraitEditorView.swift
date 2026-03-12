import SwiftUI
import SwiftData

struct PortraitEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @StateObject private var store = UserProfileStore()
    @State private var working: PortraitRecipe = .default

    var body: some View {
        List {
            Section {
                VStack(spacing: 0) {
                    PortraitView(recipe: working)
                        .frame(width: 140, height: 140)
                        .padding(.top, 18)
                        .padding(.bottom, 14)

                    if let err = store.lastError {
                        Text(err)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 16)
                            .padding(.bottom, 14)
                    } else {
                    }
                }
                .frame(maxWidth: .infinity)
                .listRowInsets(EdgeInsets())
            }

            Section {
                Picker("Hair", selection: $working.hair) {
                    Text("None").tag(HairID?.none)
                    ForEach(HairID.allCases, id: \.self) { id in
                        Text(displayName(for: id)).tag(HairID?.some(id))
                    }
                }

                Picker("Robe", selection: $working.robe) {
                    Text("Default").tag(RobeID?.none)
                    ForEach(RobeID.allCases, id: \.self) { id in
                        Text(displayName(for: id)).tag(RobeID?.some(id))
                    }
                }

                Picker("Halo", selection: $working.halo) {
                    Text("None").tag(HaloID?.none)
                    ForEach(HaloID.allCases, id: \.self) { id in
                        Text(displayName(for: id)).tag(HaloID?.some(id))
                    }
                }

                Picker("Glasses", selection: $working.glasses) {
                    Text("None").tag(GlassesID?.none)
                    ForEach(GlassesID.allCases, id: \.self) { id in
                        Text(displayName(for: id)).tag(GlassesID?.some(id))
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background {
            ZStack {
                Color(uiColor: .systemGroupedBackground)
                PortraitEditorBackgroundButterlampView()
            }
            .ignoresSafeArea()
        }
        .navigationTitle("Edit Portrait")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    store.save(recipe: working)
                    dismiss()
                }
            }
        }
        .onAppear {
            store.attach(modelContext: modelContext)
            working = store.recipe
        }
    }

    private func displayName(for hair: HairID) -> String {
        switch hair {
        case .shorthair: return "Short"
        case .longhair: return "Long"
        case .topknot: return "Topknot"
        case .yogi: return "Yogi"
        case .tiedback: return "Tied back"
        }
    }

    private func displayName(for robe: RobeID) -> String {
        switch robe {
        case .lay: return "Lay"
        case .western: return "Western"
        case .koromo: return "Koromo"
        case .gelug: return "Gelug"
        case .kagyunyingma: return "Kagyu/Nyingma"
        }
    }

    private func displayName(for halo: HaloID) -> String {
        switch halo {
        case .golden: return "Golden"
        case .silver: return "Silver"
        case .rainbow: return "Rainbow"
        }
    }

    private func displayName(for glasses: GlassesID) -> String {
        switch glasses {
        case .round: return "Round"
        case .square: return "Square"
        }
    }
}

// MARK: - Background

private struct PortraitEditorBackgroundButterlampView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var scale: CGFloat = PortraitEditorBackgroundButterlampStyle.startScale

    var body: some View {
        GeometryReader { geo in
            Image(PortraitEditorBackgroundButterlampStyle.assetName)
                .resizable()
                .scaledToFill()
                .frame(width: geo.size.width, height: geo.size.height)
                .position(x: geo.size.width / 2, y: geo.size.height / 2)
                .scaleEffect(scale, anchor: .center)
                .opacity(PortraitEditorBackgroundButterlampStyle.baseOpacity)
                .clipped()
                .allowsHitTesting(false)
                .onAppear {
                    scale = PortraitEditorBackgroundButterlampStyle.startScale
                    guard reduceMotion == false else { return }
                    withAnimation(.easeOut(duration: PortraitEditorBackgroundButterlampStyle.zoomDuration)) {
                        scale = PortraitEditorBackgroundButterlampStyle.endScale
                    }
                }
        }
    }
}

private enum PortraitEditorBackgroundButterlampStyle {
    static let assetName = "butterlamp"
    static let baseOpacity: Double = 0.14
    static let startScale: CGFloat = 0.70
    static let endScale: CGFloat = 1.04
    static let zoomDuration: Double = 50
}
