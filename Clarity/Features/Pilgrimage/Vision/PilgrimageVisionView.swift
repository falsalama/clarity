import SwiftUI
import AVFoundation
import CoreLocation
import Combine

struct PilgrimageVisionView: View {
    @StateObject private var camera = VisionCameraController()
    @StateObject private var heading = HeadingManager()
    @State private var showFX = false

    let placeName: String?
    let placeCoordinate: CLLocationCoordinate2D?
    let userLocation: CLLocation?
    let visionRadiusMeters: Double

    var body: some View {
        ZStack {
            CameraPreview(session: camera.session)
                .ignoresSafeArea()

            // FX overlays (your existing file VisionFXSettings.swift)
            VisionFXOverlay(
                placeName: placeName,
                distanceMeters: distanceMeters,
                showCloseGate: true,
                isCloseEnough: isCloseEnoughForVision
            )
            .ignoresSafeArea()

            // Simple “marker” overlay (UI-only). Shows only when close enough.
            if isCloseEnoughForVision {
                vajraYoginiOverlay
                    .allowsHitTesting(false)
            }

            // Top HUD: distance + bearing + arrow
            hudTop
                .padding(.top, 10)
                .padding(.horizontal, 12)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .allowsHitTesting(false)
        }
        // Bottom card kept clean (won’t fight your other overlays)
        .safeAreaInset(edge: .bottom) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Vision")
                    .font(.headline)

                Text("A quiet overlay for contemplation. Nothing is recorded.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.thinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .padding(.horizontal, 12)
            .padding(.bottom, 10)
        }
        .onAppear {
            camera.start()
            heading.start()
        }
        .onDisappear {
            camera.stop()
            heading.stop()
        }
        .navigationTitle(placeName ?? "Vision")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showFX = true } label: {
                    Image(systemName: "slider.horizontal.3")
                }
            }
        }
        .sheet(isPresented: $showFX) {
            VisionFXPanel()
        }
    }

    // MARK: - HUD

    private var hudTop: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(.thinMaterial)
                    .frame(width: 44, height: 44)

                Image(systemName: "location.north.fill")
                    .font(.headline)
                    .rotationEffect(.degrees(relativeArrowDegrees ?? 0))
                    .opacity(relativeArrowDegrees == nil ? 0.25 : 1.0)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(placeName ?? "Target")
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)

                if let d = distanceMeters {
                    Text("\(Int(d.rounded())) m  •  activates within \(Int(visionRadiusMeters.rounded())) m")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Distance needs location")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                if let b = bearingDegrees {
                    if let h = heading.headingDegrees {
                        Text("Bearing \(Int(b.rounded()))°  •  heading \(Int(h.rounded()))°")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Bearing \(Int(b.rounded()))°")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Text("Bearing needs location")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Image(systemName: isCloseEnoughForVision ? "checkmark.seal.fill" : "seal")
                .font(.title3)
                .foregroundStyle(isCloseEnoughForVision ? Color.accentColor : .secondary)
                .padding(.trailing, 2)
        }
        .padding(10)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    // MARK: - “Marker” overlay (UI-only)

    private var vajraYoginiOverlay: some View {
        Image("vajrayogini")
            .resizable()
            .scaledToFit()
            .frame(maxHeight: UIScreen.main.bounds.height * 0.62)
            .opacity(0.70)
            .blendMode(.screen)
            .shadow(radius: 10)
            .padding(.top, 86)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    // MARK: - Distance / gating

    private var distanceMeters: Double? {
        guard let userLocation, let placeCoordinate else { return nil }
        return userLocation.distance(
            from: CLLocation(latitude: placeCoordinate.latitude,
                             longitude: placeCoordinate.longitude)
        )
    }

    private var isCloseEnoughForVision: Bool {
        (distanceMeters ?? .greatestFiniteMagnitude) <= visionRadiusMeters
    }

    // MARK: - Bearing

    private var bearingDegrees: Double? {
        guard let userLocation, let placeCoordinate else { return nil }
        return userLocation.bearing(to: placeCoordinate)
    }

    private var relativeArrowDegrees: Double? {
        guard let b = bearingDegrees, let h = heading.headingDegrees else { return nil }
        var delta = b - h
        while delta < -180 { delta += 360 }
        while delta > 180 { delta -= 360 }
        return delta
    }
}

// MARK: - Camera Controller

final class VisionCameraController: ObservableObject {
    let session = AVCaptureSession()

    private let queue = DispatchQueue(label: "vision.camera.session")
    private var isConfigured = false

    func start() {
        queue.async {
            self.configureIfNeeded()
            if self.session.isRunning == false {
                self.session.startRunning()
            }
        }
    }

    func stop() {
        queue.async {
            if self.session.isRunning {
                self.session.stopRunning()
            }
        }
    }

    private func configureIfNeeded() {
        guard isConfigured == false else { return }
        isConfigured = true

        session.beginConfiguration()
        session.sessionPreset = .high

        guard
            let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
            let input = try? AVCaptureDeviceInput(device: device),
            session.canAddInput(input)
        else {
            session.commitConfiguration()
            return
        }

        session.addInput(input)
        session.commitConfiguration()
    }
}

// MARK: - Heading Manager

final class HeadingManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    let objectWillChange = ObservableObjectPublisher()
    
    private let manager = CLLocationManager()
    @Published var headingDegrees: Double? = nil

    override init() {
        super.init()
        manager.delegate = self
        manager.headingFilter = 1
    }

    func start() {
        if CLLocationManager.headingAvailable() {
            manager.startUpdatingHeading()
        }
    }

    func stop() {
        manager.stopUpdatingHeading()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        let deg = newHeading.trueHeading >= 0 ? newHeading.trueHeading : newHeading.magneticHeading
        headingDegrees = deg
    }
}

// MARK: - Bearing helper

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
}
