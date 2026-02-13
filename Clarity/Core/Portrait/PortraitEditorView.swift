import SwiftUI
import SwiftData

struct PortraitEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @StateObject private var store = UserProfileStore()
    @State private var working: PortraitRecipe = .default

    var body: some View {
        List {
            // Preview
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
                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
            }

            // Head (this must be inside List/Form, not top-level)
            Section("Head") {
                Picker("Face shape", selection: $working.faceShape) {
                    ForEach(FaceShapeID.allCases, id: \.self) { id in
                        Text(PortraitCatalogue.title(for: id)).tag(id)
                    }
                }

                Picker("Expression", selection: $working.expression) {
                    ForEach(ExpressionID.allCases, id: \.self) { id in
                        Text(PortraitCatalogue.title(for: id)).tag(id)
                    }
                }
            }

            Section("Hair") {
                Picker("Style", selection: $working.hairStyle) {
                    ForEach(HairStyleID.allCases, id: \.self) { id in
                        Text(PortraitCatalogue.title(for: id)).tag(id)
                    }
                }

                Picker("Colour", selection: $working.hairColour) {
                    ForEach(HairColourID.allCases, id: \.self) { id in
                        Text(PortraitCatalogue.title(for: id)).tag(id)
                    }
                }
            }

            Section("Robe") {
                Picker("Style", selection: $working.robeStyle) {
                    ForEach(RobeStyleID.allCases, id: \.self) { id in
                        Text(PortraitCatalogue.title(for: id)).tag(id)
                    }
                }

                Picker("Colour", selection: $working.robeColour) {
                    ForEach(RobeColourID.allCases, id: \.self) { id in
                        Text(PortraitCatalogue.title(for: id)).tag(id)
                    }
                }
            }

            Section("Face") {
                Picker("Skin", selection: $working.skinTone) {
                    ForEach(SkinToneID.allCases, id: \.self) { id in
                        Text("Tone \(toneLabel(for: id))").tag(id)
                    }
                }

                Picker("Eyes", selection: $working.eyeColour) {
                    ForEach(EyeColourID.allCases, id: \.self) { id in
                        Text(PortraitCatalogue.title(for: id)).tag(id)
                    }
                }
            }

            Section("Extras") {
                Toggle("Glasses", isOn: Binding(
                    get: { working.glassesStyle != nil },
                    set: { on in
                        working.glassesStyle = on ? (working.glassesStyle ?? .round) : nil
                    }
                ))

                if working.glassesStyle != nil {
                    Picker("Glasses style", selection: Binding(
                        get: { working.glassesStyle ?? .round },
                        set: { working.glassesStyle = $0 }
                    )) {
                        ForEach(GlassesStyleID.allCases, id: \.self) { id in
                            Text(PortraitCatalogue.title(for: id)).tag(id)
                        }
                    }
                }

                Picker("Background", selection: $working.backgroundStyle) {
                    ForEach(BackgroundStyleID.allCases, id: \.self) { id in
                        Text(PortraitCatalogue.title(for: id)).tag(id)
                    }
                }
            }

            Section("Hat") {
                Picker("Hat", selection: Binding(
                    get: { working.hatStyle },
                    set: { working.hatStyle = $0 }
                )) {
                    Text("None").tag(HatStyleID?.none)
                    ForEach(HatStyleID.allCases, id: \.self) { id in
                        Text(PortraitCatalogue.title(for: id)).tag(HatStyleID?.some(id))
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

    private func toneLabel(for id: SkinToneID) -> String {
        switch id {
        case .tone1: return "1"
        case .tone2: return "2"
        case .tone3: return "3"
        case .tone4: return "4"
        case .tone5: return "5"
        case .tone6: return "6"
        case .tone7: return "7"
        case .tone8: return "8"
        }
    }
}
