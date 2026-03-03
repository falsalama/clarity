import SwiftUI
import SwiftData
import MapKit
import CoreLocation
import Combine

struct PilgrimageView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var location = PilgrimageLocationManager()

    @Query private var visits: [PilgrimageVisitEntity]

    @State private var selected: PilgrimagePlace? = nil
    @State private var spin: Double = 0

    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var didAutoCenter: Bool = false

    init() {
        _visits = Query(sort: [SortDescriptor(\PilgrimageVisitEntity.visitedAt, order: .reverse)])
    }

    private var visitedSet: Set<String> { Set(visits.map(\.placeID)) }
    private var visitedCount: Int { visitedSet.count }

    private var userLocation: CLLocation? {
        if case let .located(loc) = location.state { return loc }
        return nil
    }

    private func distanceString(to place: PilgrimagePlace) -> String? {
        guard let loc = userLocation else { return nil }
        let d = loc.distance(from: CLLocation(latitude: place.coordinate.latitude, longitude: place.coordinate.longitude))
        if d < 1000 { return "\(Int(d)) m" }
        return String(format: "%.1f km", d / 1000.0)
    }

    private func markVisited(_ place: PilgrimagePlace) {
        if let existing = visits.first(where: { $0.placeID == place.id }) {
            existing.visitedAt = existing.visitedAt
            return
        }
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
            NavigationStack {
                PilgrimagePlaceSheet(
                    place: place,
                    isVisited: visitedSet.contains(place.id),
                    spin: spin,
                    onSpin: { withAnimation(.easeOut(duration: 0.35)) { spin += 360 } },
                    onMarkVisited: { markVisited(place) }
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
                span: MKCoordinateSpan(latitudeDelta: 6, longitudeDelta: 6)
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

    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 6) {
                Text(place.name)
                    .font(.title3.weight(.semibold))
                Text(place.subtitle)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Button {
                onSpin()
            } label: {
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

            NavigationLink {
                PilgrimageVisionView()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "camera")
                    Text("Open Vision")
                        .font(.headline)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }
            .buttonStyle(.bordered)

            Button {
                onMarkVisited()
            } label: {
                Text(isVisited ? "Visited" : "Mark visited")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .disabled(isVisited)

            Spacer(minLength: 0)
        }
        .padding(18)
    }
}
