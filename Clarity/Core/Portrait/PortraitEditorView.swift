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
                        Text("Tap options below to customise.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .padding(.bottom, 14)
                    }
                }
                .frame(maxWidth: .infinity)
                .listRowInsets(EdgeInsets())
            }
            
            Section("Hair") {
                Picker("Style", selection: $working.hair) {
                    Text("None").tag(HairID?.none)
                    ForEach(HairID.allCases, id: \.self) { id in
                        Text(displayName(for: id)).tag(HairID?.some(id))
                    }
                }
            }
            
            Section("Robe") {
                Picker("Style", selection: $working.robe) {
                    Text("Default").tag(RobeID?.none)
                    ForEach(RobeID.allCases, id: \.self) { id in
                        Text(displayName(for: id)).tag(RobeID?.some(id))
                    }
                }
            }
            
            Section("Halo") {
                Picker("Colour", selection: $working.halo) {
                    Text("None").tag(HaloID?.none)
                    ForEach(HaloID.allCases, id: \.self) { id in
                        Text(displayName(for: id)).tag(HaloID?.some(id))
                    }
                }
            }
            Section("Glasses") {
                Picker("Style", selection: $working.glasses) {
                    Text("None").tag(GlassesID?.none)
                    ForEach(GlassesID.allCases, id: \.self) { id in
                        Text(displayName(for: id)).tag(GlassesID?.some(id))
                    }
                }
            }
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
        case .longhair:  return "Long"
        case .topknot:   return "Topknot"
        case .yogi:      return "Yogi"
        case .tiedBack:  return "Tied back"
        }
    }

    private func displayName(for robe: RobeID) -> String {
        switch robe {
        case .lay:     return "Lay"
        case .western: return "Western"
        case .koromo:  return "Koromo"
        case .gelug:   return "Gelug"
        case .kagyunyingma:  return "Kagyu/Nyingma"
        }
    }

    private func displayName(for halo: HaloID) -> String {
        switch halo {
        case .golden:  return "Golden"
        case .silver:  return "Silver"
        case .rainbow: return "Rainbow"
        }
    }
    private func displayName(for glasses: GlassesID) -> String {
        switch glasses {
        case .round:  return "Round"
        case .square: return "Square"
        }
    }
}
