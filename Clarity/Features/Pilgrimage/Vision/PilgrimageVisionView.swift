// PilgrimageVisionView.swift

import SwiftUI
import CoreLocation
import ARKit
import RealityKit
import Combine

struct PilgrimageVisionView: View {
    @StateObject private var location = VisionLocationManager()

    let placeName: String?
    let placeCoordinate: CLLocationCoordinate2D?
    let visionRadiusMeters: Double
    let visionAssetName: String
    
    var body: some View {
        ZStack {
            SimplePinnedARView(
                isActive: true,
                assetName: visionAssetName,
                heightMeters: 2.5
            )
            .ignoresSafeArea()

            // Avoid “dead” feeling while AR + first GPS fix comes in.
            if location.effectiveLocation == nil {
                ProgressView("Getting a fix…")
                    .padding(12)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }

            hudTop
                .padding(.top, 10)
                .padding(.horizontal, 12)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .safeAreaInset(edge: .bottom) { bottomCard }
        .onAppear { location.start() }
        .onDisappear { location.stop() }
        .navigationTitle(placeName ?? "Vision")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Derived

    private var distanceMeters: Double? {
        guard let user = location.effectiveLocation, let target = placeCoordinate else { return nil }
        return user.distance(from: CLLocation(latitude: target.latitude, longitude: target.longitude))
    }

    private var isCloseEnough: Bool {
        (distanceMeters ?? .greatestFiniteMagnitude) <= visionRadiusMeters
    }

    private var bearingDegrees: Double? {
        guard let user = location.effectiveLocation, let target = placeCoordinate else { return nil }
        return user.bearing(to: target)
    }

    private var relativeArrowDegrees: Double? {
        guard let b = bearingDegrees, let h = location.effectiveHeadingDegrees else { return nil }
        var delta = b - h
        while delta < -180 { delta += 360 }
        while delta > 180 { delta -= 360 }
        return delta
    }

    // MARK: - HUD

    private var hudTop: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(.thinMaterial)
                    .frame(width: 44, height: 44)

                Image(systemName: "arrow.up")
                    .font(.headline)
                    .rotationEffect(.degrees(relativeArrowDegrees ?? 0))
                    .opacity(relativeArrowDegrees == nil ? 0.25 : 1.0)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(placeName ?? "Target")
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)

                if let d = distanceMeters {
                    Text("\(Int(d.rounded())) m - activates within \(Int(visionRadiusMeters.rounded())) m")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Waiting for location…")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                if let b = bearingDegrees {
                    Text("Bearing \(Int(b.rounded()))°")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Bearing unavailable")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Image(systemName: isCloseEnough ? "checkmark.seal.fill" : "seal")
                .font(.title3)
                .foregroundStyle(isCloseEnough ? Color.accentColor : .secondary)
                .padding(.trailing, 2)
        }
        .padding(10)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var bottomCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(placeName ?? "Vision")
                .font(.headline)

            if let d = distanceMeters {
                Text(isCloseEnough ? "Close enough - look around." : "Move closer to reveal.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                Text("\(Int(d.rounded())) m (within \(Int(visionRadiusMeters.rounded())) m)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text("Waiting for a location fix… go outdoors.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            // Optional: quick sanity diagnostics (kept subtle)
            if let acc = location.horizontalAccuracy {
                Text("Accuracy \(Int(acc.rounded()))m")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .padding(.horizontal, 12)
        .padding(.bottom, 10)
    }
}

// MARK: - AR view: minimal, stable, no raycast, no per-frame updates

private struct SimplePinnedARView: UIViewRepresentable {
    let isActive: Bool
    let assetName: String
    let heightMeters: Float

    func makeUIView(context: Context) -> ARView {
        let view = ARView(frame: .zero)

        let config = ARWorldTrackingConfiguration()
        config.planeDetection = []                 // no plane / no raycast
        config.environmentTexturing = .automatic

        view.session.run(config, options: [.resetTracking, .removeExistingAnchors])

        context.coordinator.attach(to: view)
        return view
    }

    func updateUIView(_ uiView: ARView, context: Context) {
        context.coordinator.update(isActive: isActive, assetName: assetName, heightMeters: heightMeters)
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator {
        private weak var arView: ARView?
        private var anchor: AnchorEntity?
        private var didPlace = false
        private var retryCount = 0
        private var maxRetries = 12    // ~3 seconds at 0.25s intervals

        func attach(to view: ARView) {
            self.arView = view
        }

        func update(isActive: Bool, assetName: String, heightMeters: Float) {
            guard let arView else { return }

            if isActive == false {
                anchor?.isEnabled = false
                didPlace = false
                retryCount = 0
                return
            }

            // active
            anchor?.isEnabled = true
            guard didPlace == false else { return }

            guard let frame = arView.session.currentFrame else {
                guard retryCount < maxRetries else { return }
                retryCount += 1
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
                    guard let self else { return }
                    self.update(isActive: isActive, assetName: assetName, heightMeters: heightMeters)
                }
                return
            }

            // remove any old
            anchor?.removeFromParent()
            anchor = nil

            // place once: 1.5m in front of camera
            let cam = frame.camera.transform
            let camPos = SIMD3<Float>(cam.columns.3.x, cam.columns.3.y, cam.columns.3.z)
            let forward = -SIMD3<Float>(cam.columns.2.x, cam.columns.2.y, cam.columns.2.z)
            let pos = camPos + forward * 1.5

            var t = matrix_identity_float4x4
            t.columns.3 = SIMD4<Float>(pos.x, pos.y, pos.z, 1)

            let newAnchor = AnchorEntity(world: t)

            let plane = makeTexturedPlane(assetName: assetName, heightMeters: heightMeters)
            newAnchor.addChild(plane)

            arView.scene.addAnchor(newAnchor)

            anchor = newAnchor
            didPlace = true

            // Face the camera ONCE at placement (prevents “thin edge” start)
            faceCameraOnce(arView: arView, anchor: newAnchor, model: plane)
        }

        private func faceCameraOnce(arView: ARView, anchor: AnchorEntity, model: ModelEntity) {
            guard let frame = arView.session.currentFrame else { return }

            let cam = frame.camera.transform
            let camPos = SIMD3<Float>(cam.columns.3.x, cam.columns.3.y, cam.columns.3.z)

            let worldPos = anchor.position(relativeTo: nil)
            let dir = camPos - worldPos
            let yaw = atan2(dir.x, dir.z)
            let yawOnly = simd_quatf(angle: yaw, axis: [0, 1, 0])

            // Preserve your “stand up” rotation
            let standUp = simd_quatf(angle: .pi / 2, axis: [1, 0, 0])
            model.transform.rotation = simd_mul(yawOnly, standUp)
        }

        private func makeTexturedPlane(assetName: String, heightMeters: Float) -> ModelEntity {
            let h = max(0.6, heightMeters)
            let w = h * 0.75

            // plane is XZ; rotate once to stand upright (no other axis work, no camera-facing)
            let mesh = MeshResource.generatePlane(width: w, depth: h)
            var material = UnlitMaterial()

            if #available(iOS 18.0, *) { material.faceCulling = .none }

            if let ui = UIImage(named: assetName),
               let cg = ui.cgImage,
               let tex = try? TextureResource.generate(from: cg, options: .init(semantic: .color)) {
                material.color = .init(texture: .init(tex))
                material.blending = .transparent(opacity: 1.0)
            } else {
                material.color = .init(tint: .systemPink)
                material.blending = .opaque
                print("AR: UIImage(named:) failed for asset:", assetName)
            }

            let e = ModelEntity(mesh: mesh, materials: [material])
            e.transform.rotation = simd_quatf(angle: .pi / 2, axis: [1, 0, 0]) // stand up
            e.transform.translation.y = h * 0.5
            return e
        }
    }
}
// MARK: - Location + Heading (filtered, not frozen)
//
// Logic:
// - Freezing “close enough” is what caused distance to stick at 12m and bearings to become nonsense.
// - Indoors, GPS + compass jitter. So we keep updating but apply smoothing.
// - Heading: when moving, prefer GPS course (stable). When not moving, prefer compass.
// - Always keep heading updates running; never lock them.

private final class VisionLocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()

    @Published private(set) var lastLocation: CLLocation? = nil
    @Published private(set) var headingDegrees: Double? = nil

    @Published private(set) var horizontalAccuracy: CLLocationAccuracy? = nil
    @Published private(set) var headingAccuracy: CLLocationDirectionAccuracy? = nil

    private var filteredLocation: CLLocation? = nil
    private var filteredHeading: Double? = nil

    var effectiveLocation: CLLocation? { filteredLocation ?? lastLocation }

    var effectiveHeadingDegrees: Double? {
        // Prefer GPS course when moving (typically more trustworthy than compass in urban/indoors).
        if let loc = lastLocation, loc.speed >= 0.8, loc.course >= 0 {
            return loc.course
        }
        return filteredHeading ?? headingDegrees
    }

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.activityType = .fitness
        manager.distanceFilter = 1
        manager.headingFilter = 1
        manager.headingOrientation = .portrait
    }

    func start() {
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
        if CLLocationManager.headingAvailable() {
            manager.startUpdatingHeading()
        }
    }

    func stop() {
        manager.stopUpdatingLocation()
        manager.stopUpdatingHeading()
        filteredLocation = nil
        filteredHeading = nil
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let newLoc = locations.last else { return }
        lastLocation = newLoc
        horizontalAccuracy = newLoc.horizontalAccuracy

        // Smoothing:
        // - If accuracy is good, respond faster.
        // - If accuracy is poor, respond slower (avoid jumps).
        let acc = max(newLoc.horizontalAccuracy, 1)
        let alpha: Double
        switch acc {
        case ..<10: alpha = 0.35
        case 10..<25: alpha = 0.22
        case 25..<60: alpha = 0.12
        default: alpha = 0.07
        }

        if let f = filteredLocation {
            filteredLocation = f.blended(towards: newLoc, alpha: alpha)
        } else {
            filteredLocation = newLoc
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        headingAccuracy = newHeading.headingAccuracy

        // If trueHeading is invalid (negative), fall back to magnetic.
        let raw = (newHeading.trueHeading >= 0) ? newHeading.trueHeading : newHeading.magneticHeading
        headingDegrees = raw

        // Heading smoothing (circular).
        let alpha: Double
        if newHeading.headingAccuracy >= 0, newHeading.headingAccuracy <= 10 {
            alpha = 0.25
        } else if newHeading.headingAccuracy >= 0, newHeading.headingAccuracy <= 25 {
            alpha = 0.15
        } else {
            alpha = 0.08
        }

        if let f = filteredHeading {
            filteredHeading = circularBlend(from: f, to: raw, alpha: alpha)
        } else {
            filteredHeading = raw
        }
    }

    private func circularBlend(from a: Double, to b: Double, alpha: Double) -> Double {
        // Blend angles in degrees with wrap-around.
        var delta = b - a
        while delta < -180 { delta += 360 }
        while delta > 180 { delta -= 360 }
        var out = a + delta * alpha
        while out < 0 { out += 360 }
        while out >= 360 { out -= 360 }
        return out
    }
}

private extension CLLocation {
    func bearing(to coordinate: CLLocationCoordinate2D) -> Double {
        let lat1 = self.coordinate.latitude * .pi / 180
        let lon1 = self.coordinate.longitude * .pi / 180
        let lat2 = coordinate.latitude * .pi / 180
        let lon2 = coordinate.longitude * .pi / 180

        let dLon = lon2 - lon1
        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
        var brng = atan2(y, x) * 180 / .pi
        if brng < 0 { brng += 360 }
        return brng
    }

    /// Blend two CLLocation fixes by interpolating lat/lon and carrying over other fields sensibly.
    func blended(towards other: CLLocation, alpha: Double) -> CLLocation {
        let a = max(0.0, min(1.0, alpha))

        let lat = coordinate.latitude + (other.coordinate.latitude - coordinate.latitude) * a
        let lon = coordinate.longitude + (other.coordinate.longitude - coordinate.longitude) * a

        let alt = altitude + (other.altitude - altitude) * a

        // Use the better (smaller) accuracy as we converge.
        let hAcc = min(horizontalAccuracy, other.horizontalAccuracy)
        let vAcc = min(verticalAccuracy, other.verticalAccuracy)

        // Speed/course can be noisy; keep the newer values.
        let spd = other.speed
        let crs = other.course

        return CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon),
            altitude: alt,
            horizontalAccuracy: hAcc,
            verticalAccuracy: vAcc,
            course: crs,
            speed: spd,
            timestamp: other.timestamp
        )
    }
}
