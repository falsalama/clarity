import SwiftUI
import AVFoundation
import Combine

struct PilgrimageVisionView: View {
    @StateObject private var camera = VisionCameraController()

    var body: some View {
        ZStack {
            CameraPreview(session: camera.session)
                .ignoresSafeArea()

            VStack {
                Spacer()
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
                .padding()
            }
        }
        .onAppear { camera.start() }
        .onDisappear { camera.stop() }
        .navigationTitle("Vision")
        .navigationBarTitleDisplayMode(.inline)
    }
}

@MainActor
final class VisionCameraController: ObservableObject {
    let session = AVCaptureSession()
    private var isConfigured = false

    func start() {
        configureIfNeeded()
        if session.isRunning == false {
            session.startRunning()
        }
    }

    func stop() {
        if session.isRunning {
            session.stopRunning()
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
