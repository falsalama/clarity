// PilgrimageView.swift

import SwiftUI
import SwiftData
import MapKit
import CoreLocation

struct PilgrimageView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var location = PilgrimageLocationManager()

    @Query private var visits: [PilgrimageVisitEntity]

    @State private var selected: PilgrimagePlace? = nil
    @State private var spin: Double = 0

    @State private var cameraPosition: MapCameraPosition = .region(Self.defaultRegion)
    @State private var didAutoCenter: Bool = false

    init() {
        _visits = Query(sort: [SortDescriptor(\PilgrimageVisitEntity.visitedAt, order: .reverse)])
    }

    private static var defaultRegion: MKCoordinateRegion {
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 20.0, longitude: 0.0),
            span: MKCoordinateSpan(latitudeDelta: 120, longitudeDelta: 180)
        )
    }

    private var visitedSet: Set<String> { Set(visits.map(\.placeID)) }
    private var visitedCount: Int { visitedSet.count }

    private var userLocation: CLLocation? {
        if case let .located(loc) = location.state { return loc }
        return nil
    }

    private func distanceMeters(to place: PilgrimagePlace) -> Double? {
        guard let loc = userLocation else { return nil }
        return loc.distance(from: CLLocation(latitude: place.coordinate.latitude,
                                            longitude: place.coordinate.longitude))
    }

    private func distanceString(to place: PilgrimagePlace) -> String? {
        guard let d = distanceMeters(to: place) else { return nil }
        if d < 1000 { return "\(Int(d.rounded())) m" }
        return String(format: "%.1f km", d / 1000.0)
    }

    private func markVisited(_ place: PilgrimagePlace) {
        if visits.first(where: { $0.placeID == place.id }) != nil { return }
        modelContext.insert(PilgrimageVisitEntity(placeID: place.id, visitedAt: Date()))
        do { try modelContext.save() } catch { /* best-effort */ }
    }

    var body: some View {
        List {
            Section {
                HStack {
                    Label("Visited", systemImage: "seal.fill")
                    Spacer()
                    Text("\(visitedCount)")
                        .foregroundStyle(.secondary)
                }

                Button {
                    location.requestOneShotLocation()
                } label: {
                    switch location.state {
                    case .idle:
                        Label("Find nearby", systemImage: "location")
                    case .locating:
                        Label("Locating…", systemImage: "location.fill")
                    case .denied:
                        Label("Location disabled", systemImage: "location.slash")
                    case .unavailable:
                        Label("Location unavailable", systemImage: "exclamationmark.triangle")
                    case .located:
                        Label("Nearby updated", systemImage: "location.circle.fill")
                    }
                }
                .buttonStyle(.plain)
            } header: {
                Text("Pilgrimage")
            }

            Section {
                Map(position: $cameraPosition) {
                    ForEach(PilgrimagePlaces.all) { place in
                        Annotation(place.name, coordinate: place.coordinate) {
                            Button {
                                selected = place
                                withAnimation(.easeOut(duration: 0.35)) { spin += 360 }
                            } label: {
                                towerMarker(isVisited: visitedSet.contains(place.id))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .frame(height: 280)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .listRowInsets(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))
            } header: {
                Text("Map")
            }

            Section {
                ForEach(PilgrimagePlaces.all) { place in
                    Button {
                        selected = place
                        withAnimation(.easeOut(duration: 0.35)) { spin += 360 }
                    } label: {
                        HStack(spacing: 12) {
                            towerRowIcon(isVisited: visitedSet.contains(place.id))

                            VStack(alignment: .leading, spacing: 2) {
                                Text(place.name)
                                    .font(.subheadline.weight(.semibold))
                                Text(place.subtitle)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            if let dist = distanceString(to: place) {
                                Text(dist)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            } else {
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .contentShape(Rectangle())
                        .padding(.vertical, 6)
                    }
                    .buttonStyle(.plain)
                }
            } header: {
                Text("Places")
            }
        }
        .navigationTitle("Pilgrimage")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selected) { place in
            let d = distanceMeters(to: place)
            let closeEnough = (d ?? .greatestFiniteMagnitude) <= place.visionRadiusMeters

            NavigationStack {
                PilgrimagePlaceSheet(
                    place: place,
                    isVisited: visitedSet.contains(place.id),
                    spin: spin,
                    onSpin: { withAnimation(.easeOut(duration: 0.35)) { spin += 360 } },
                    onMarkVisited: { markVisited(place) },
                    userLocation: userLocation,
                    distanceMeters: d,
                    isCloseEnoughForVision: closeEnough
                )
                .navigationBarTitleDisplayMode(.inline)
            }
            .presentationDetents([.medium, .large])
        }
        .onReceive(location.$state) { newValue in
            guard didAutoCenter == false else { return }
            guard case let .located(loc) = newValue else { return }
            didAutoCenter = true

            let region = MKCoordinateRegion(
                center: loc.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.06, longitudeDelta: 0.06)
            )
            cameraPosition = .region(region)
        }
    }

    private func towerMarker(isVisited: Bool) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(radius: 2, y: 1)

            Image(systemName: isVisited ? "dot.radiowaves.left.and.right" : "dot.circle")
                .font(.headline)
                .foregroundStyle(isVisited ? .primary : .secondary)
                .padding(10)
        }
    }

    private func towerRowIcon(isVisited: Bool) -> some View {
        Image(systemName: isVisited ? "seal.fill" : "seal")
            .foregroundStyle(isVisited ? .primary : .secondary)
            .frame(width: 24)
    }
}

private struct PilgrimagePlaceSheet: View {
    let place: PilgrimagePlace
    let isVisited: Bool
    let spin: Double
    let onSpin: () -> Void
    let onMarkVisited: () -> Void

    let userLocation: CLLocation?
    let distanceMeters: Double?
    let isCloseEnoughForVision: Bool

    @State private var showVision: Bool = false

    // This fixes the crash: PilgrimageVisionView (or something in its tree) expects CapsuleStore.
    @EnvironmentObject private var capsuleStore: CapsuleStore

    private var visionGateSubtitle: String {
        let radius = Int(place.visionRadiusMeters.rounded())
        guard let d = distanceMeters else {
            return "Location needed - Vision activates within \(radius)m."
        }

        let dist = d < 1000 ? "\(Int(d.rounded()))m" : String(format: "%.1fkm", d / 1000.0)

        if isCloseEnoughForVision {
            return "Vision available - \(dist) away (within \(radius)m)."
        } else {
            return "Move closer - \(dist) away (activates within \(radius)m)."
        }
    }

    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 6) {
                Text(place.name)
                    .font(.title3.weight(.semibold))
                Text(place.subtitle)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Button { onSpin() } label: {
                ZStack {
                    Circle()
                        .fill(Color(.secondarySystemBackground))
                        .frame(width: 110, height: 110)

                    Image(systemName: "building.columns")
                        .font(.title.weight(.semibold))
                        .rotationEffect(.degrees(spin))
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text("Spin"))

            Text(place.teaching)
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 18)

            VStack(spacing: 8) {
                Button {
                    showVision = true
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "camera")
                        Text("Open Vision")
                            .font(.headline)
                        Spacer()
                        if isCloseEnoughForVision {
                            Text("Ready")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.secondary)
                        }
                        Image(systemName: "chevron.right")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .disabled(distanceMeters == nil || !isCloseEnoughForVision)

                Text(visionGateSubtitle)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .fullScreenCover(isPresented: $showVision) {
                NavigationStack {
                    PilgrimageVisionView(
                        placeName: place.name,
                        placeCoordinate: place.coordinate,
                        visionRadiusMeters: place.visionRadiusMeters,
                        visionAssetName:
                            (place.id == "vajra_yogini_norham") ? "vajrayogini" :
                            (place.id == "shakyamuni_wells") ? "shakyamuni" :
                            "gururinpoche"
                    )
                    
                
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            Button("Close") { showVision = false }
                        }
                    }
                }
                .environmentObject(capsuleStore)
            }

            Button { onMarkVisited() } label: {
                Text(isVisited ? "Visited" : "Mark visited")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.bordered)
            .disabled(isVisited)

            Spacer(minLength: 0)
        }
        .padding(18)
    }
}
