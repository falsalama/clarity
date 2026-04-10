import SwiftUI

struct LightOfferingView: View {
    @State private var lamps: [OfferingLamp] = []
    @State private var waterBowls: [OfferingWaterBowl] = []
    @State private var incenseSticks: [OfferingIncense] = []
    @State private var dragStartPositions: [UUID: CGPoint] = [:]
    @State private var dragStartWaterBowlPositions: [UUID: CGPoint] = [:]
    @State private var dragStartIncensePositions: [UUID: CGPoint] = [:]
    @State private var selectedBackground = OfferingBackground.buddha

    // MARK: - Buddha Background
    private let buddhaBackgroundOpacity: Double = 1.0

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .bottomTrailing) {
                LinearGradient(
                    colors: [
                        Color.black,
                        Color(red: 0.08, green: 0.06, blue: 0.02)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                Image(selectedBackground.assetName)
                    .resizable()
                    .renderingMode(.original)
                    .scaledToFit()
                    .frame(width: min(proxy.size.width * 0.9, 400))
                    .position(x: proxy.size.width / 2, y: proxy.size.height * 0.26)
                    .opacity(buddhaBackgroundOpacity)
                    .allowsHitTesting(false)

                ForEach(waterBowls) { bowl in
                    waterBowlView(for: bowl, in: proxy.size)
                }

                ForEach(incenseSticks) { incense in
                    incenseView(for: incense, in: proxy.size)
                }

                ForEach(lamps) { lamp in
                    lampView(for: lamp, in: proxy.size)
                }

                addButtons(for: proxy.size)
                    .padding(.trailing, 22)
                    .padding(.bottom, 24)
            }
            .onAppear {
                if lamps.isEmpty {
                    lamps = [OfferingLamp(position: initialLampPosition(for: 0, in: proxy.size))]
                } else {
                    clampAllLampPositions(in: proxy.size)
                }

                if incenseSticks.isEmpty == false {
                    clampAllIncensePositions(in: proxy.size)
                }

                if waterBowls.isEmpty == false {
                    clampAllWaterBowlPositions(in: proxy.size)
                }
            }
            .onChange(of: proxy.size) { _, newSize in
                clampAllLampPositions(in: newSize)
                clampAllWaterBowlPositions(in: newSize)
                clampAllIncensePositions(in: newSize)
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                backgroundMenu
            }
        }
        .toolbarBackground(.hidden, for: .navigationBar)
    }

    private var backgroundMenu: some View {
        Menu {
            ForEach(OfferingBackground.allCases) { background in
                Button {
                    selectedBackground = background
                } label: {
                    if background == selectedBackground {
                        Label(background.menuTitle, systemImage: "checkmark")
                    } else {
                        Text(background.menuTitle)
                    }
                }
            }
        } label: {
            Image(systemName: "chevron.down")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(
                    Circle()
                        .fill(Color.white.opacity(0.12))
                )
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.16), lineWidth: 1)
                )
        }
        .shadow(color: .black.opacity(0.22), radius: 8, x: 0, y: 4)
        .accessibilityLabel("Change deity background")
    }

    @ViewBuilder
    private func lampView(for lamp: OfferingLamp, in size: CGSize) -> some View {
        let lampSize = lampMetrics(for: lamp.position, in: size)

        MovableLampView(
            assetName: lamp.isLit ? "butterlamp" : "butterlampunlit",
            size: lampSize,
            motionSeed: lamp.motionSeed
        )
        .position(lamp.position)
        .zIndex(lampDepthZIndex(for: lamp.position, in: size))
        .gesture(dragGesture(for: lamp.id, in: size))
        .simultaneousGesture(
            TapGesture()
                .onEnded {
                    withAnimation(.easeInOut(duration: 0.18)) {
                        toggleLamp(id: lamp.id)
                    }
                }
        )
    }

    @ViewBuilder
    private func waterBowlView(for bowl: OfferingWaterBowl, in size: CGSize) -> some View {
        let bowlSize = waterBowlMetrics(for: bowl.position, in: size)

        MovableWaterBowlView(
            size: bowlSize,
            isFilled: bowl.isFilled,
            motionSeed: bowl.motionSeed
        )
        .position(bowl.position)
        .zIndex(waterBowlDepthZIndex(for: bowl.position, in: size))
        .gesture(dragWaterBowlGesture(for: bowl.id, in: size))
        .simultaneousGesture(
            TapGesture()
                .onEnded {
                    withAnimation(.easeInOut(duration: 0.22)) {
                        fillWaterBowl(id: bowl.id)
                    }
                }
        )
    }

    @ViewBuilder
    private func incenseView(for incense: OfferingIncense, in size: CGSize) -> some View {
        let incenseSize = incenseMetrics(for: incense.position, in: size)

        MovableIncenseView(
            size: incenseSize,
            motionSeed: incense.motionSeed
        )
        .position(incense.position)
        .zIndex(incenseDepthZIndex(for: incense.position, in: size))
        .gesture(dragIncenseGesture(for: incense.id, in: size))
    }

    private func addButtons(for size: CGSize) -> some View {
        VStack(spacing: 12) {
            Button {
                withAnimation(.spring(response: 0.32, dampingFraction: 0.9)) {
                    waterBowls.append(OfferingWaterBowl(position: nextWaterBowlPosition(in: size)))
                    clampAllWaterBowlPositions(in: size)
                }
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 34, height: 34)
                    .background(
                        Circle()
                            .fill(Color.white.opacity(0.10))
                    )
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.14), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .shadow(color: .black.opacity(0.2), radius: 7, x: 0, y: 3)
            .accessibilityLabel("Add water bowl")

            Button {
                withAnimation(.spring(response: 0.32, dampingFraction: 0.9)) {
                    incenseSticks.append(OfferingIncense(position: nextIncensePosition(in: size)))
                    clampAllIncensePositions(in: size)
                }
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 38, height: 38)
                    .background(
                        Circle()
                            .fill(Color.white.opacity(0.10))
                    )
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.14), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .shadow(color: .black.opacity(0.22), radius: 8, x: 0, y: 4)
            .accessibilityLabel("Add incense")

            Button {
                withAnimation(.spring(response: 0.32, dampingFraction: 0.9)) {
                    lamps.append(OfferingLamp(position: nextLampPosition(in: size)))
                    clampAllLampPositions(in: size)
                }
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 54, height: 54)
                    .background(
                        Circle()
                            .fill(Color.white.opacity(0.12))
                    )
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.16), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .shadow(color: .black.opacity(0.26), radius: 10, x: 0, y: 6)
            .accessibilityLabel("Add butterlamp")
        }
    }

    private func lampMetrics(in size: CGSize) -> CGSize {
        let width = min(max(size.width * 0.3, 124), 168)
        let height = width * (553.0 / 345.0)
        return CGSize(width: width, height: height)
    }

    private func lampMetrics(for position: CGPoint, in size: CGSize) -> CGSize {
        let base = lampMetrics(in: size)
        let scale = lampPerspectiveScale(for: position, in: size)
        return CGSize(width: base.width * scale, height: base.height * scale)
    }

    private func waterBowlMetrics(in size: CGSize) -> CGSize {
        let width = min(max(size.width * 0.18, 58), 94)
        let height = width * (532.0 / 625.0)
        return CGSize(width: width, height: height)
    }

    private func waterBowlMetrics(for position: CGPoint, in size: CGSize) -> CGSize {
        let base = waterBowlMetrics(in: size)
        let scale = lampPerspectiveScale(for: position, in: size)
        return CGSize(width: base.width * scale, height: base.height * scale)
    }

    private func incenseMetrics(in size: CGSize) -> CGSize {
        let width = min(max(size.width * 0.21, 64), 98)
        let height = width * (1145.0 / 378.0)
        return CGSize(width: width, height: height)
    }

    private func incenseMetrics(for position: CGPoint, in size: CGSize) -> CGSize {
        let base = incenseMetrics(in: size)
        let scale = lampPerspectiveScale(for: position, in: size)
        return CGSize(width: base.width * scale, height: base.height * scale)
    }

    private func initialLampPosition(for index: Int, in size: CGSize) -> CGPoint {
        let lampSize = lampMetrics(in: size)
        let bottomY = size.height - (lampSize.height * 0.5 + 18)
        let horizontalSpacing = lampSize.width * 0.74
        let slot = alternatingSlot(for: index)
        let x = size.width / 2 + CGFloat(slot) * horizontalSpacing
        return clampedLampPosition(CGPoint(x: x, y: bottomY), in: size)
    }

    private func nextLampPosition(in size: CGSize) -> CGPoint {
        initialLampPosition(for: lamps.count, in: size)
    }

    private func initialWaterBowlPosition(for index: Int, in size: CGSize) -> CGPoint {
        let bowlSize = waterBowlMetrics(in: size)
        let bottomY = size.height - (bowlSize.height * 0.34 + 10)
        let spacing = bowlSize.width * 1.45
        let slot = alternatingSlot(for: index)
        let x = size.width * 0.68 + CGFloat(slot) * spacing
        return clampedWaterBowlPosition(CGPoint(x: x, y: bottomY), in: size)
    }

    private func nextWaterBowlPosition(in size: CGSize) -> CGPoint {
        initialWaterBowlPosition(for: waterBowls.count, in: size)
    }

    private func initialIncensePosition(for index: Int, in size: CGSize) -> CGPoint {
        let incenseSize = incenseMetrics(in: size)
        let bottomY = size.height - (incenseSize.height * 0.34 + 24)
        let spacing = incenseSize.width * 2.4
        let slot = alternatingSlot(for: index)
        let x = size.width * 0.32 + CGFloat(slot) * spacing
        return clampedIncensePosition(CGPoint(x: x, y: bottomY), in: size)
    }

    private func nextIncensePosition(in size: CGSize) -> CGPoint {
        initialIncensePosition(for: incenseSticks.count, in: size)
    }

    private func alternatingSlot(for index: Int) -> Int {
        guard index > 0 else { return 0 }
        let step = (index + 1) / 2
        return index.isMultiple(of: 2) ? -step : step
    }

    private func clampedLampPosition(_ point: CGPoint, in size: CGSize) -> CGPoint {
        let verticalRange = lampVerticalRange(in: size)
        var clampedY = min(max(point.y, verticalRange.lowerBound), verticalRange.upperBound)

        for _ in 0..<2 {
            let lampSize = lampMetrics(for: CGPoint(x: point.x, y: clampedY), in: size)
            let maxY = size.height - (lampSize.height * 0.5 + 18)
            clampedY = min(max(point.y, verticalRange.lowerBound), maxY)
        }

        let lampSize = lampMetrics(for: CGPoint(x: point.x, y: clampedY), in: size)
        let horizontalInset = lampSize.width * 0.5 + 4

        return CGPoint(
            x: min(max(point.x, horizontalInset), size.width - horizontalInset),
            y: clampedY
        )
    }

    private func lampDepthZIndex(for position: CGPoint, in size: CGSize) -> Double {
        let verticalRange = lampVerticalRange(in: size)
        let travel = max(verticalRange.upperBound - verticalRange.lowerBound, 1)
        let progress = (position.y - verticalRange.lowerBound) / travel
        return Double(progress)
    }

    private func incenseDepthZIndex(for position: CGPoint, in size: CGSize) -> Double {
        lampDepthZIndex(for: position, in: size) + 0.1
    }

    private func waterBowlDepthZIndex(for position: CGPoint, in size: CGSize) -> Double {
        lampDepthZIndex(for: position, in: size) + 0.05
    }

    private func lampVerticalRange(in size: CGSize) -> ClosedRange<CGFloat> {
        let baseSize = lampMetrics(in: size)
        let minY = max(size.height * 0.56, baseSize.height * 0.38)
        let maxY = size.height - (baseSize.height * 0.5 + 18)
        return minY...maxY
    }

    private func lampPerspectiveScale(for position: CGPoint, in size: CGSize) -> CGFloat {
        let verticalRange = lampVerticalRange(in: size)
        let travel = max(verticalRange.upperBound - verticalRange.lowerBound, 1)
        let progress = min(max((position.y - verticalRange.lowerBound) / travel, 0), 1)
        return 0.68 + (progress * 0.32)
    }

    private func dragGesture(for lampID: UUID, in size: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 4, coordinateSpace: .local)
            .onChanged { value in
                guard let index = lamps.firstIndex(where: { $0.id == lampID }) else { return }

                if dragStartPositions[lampID] == nil {
                    dragStartPositions[lampID] = lamps[index].position
                }

                let start = dragStartPositions[lampID] ?? lamps[index].position
                let nextPoint = CGPoint(
                    x: start.x + value.translation.width,
                    y: start.y + value.translation.height
                )

                lamps[index].position = resolvedLampPosition(for: index, proposed: nextPoint, in: size)
            }
            .onEnded { value in
                guard let index = lamps.firstIndex(where: { $0.id == lampID }) else { return }

                let start = dragStartPositions[lampID] ?? lamps[index].position
                let nextPoint = CGPoint(
                    x: start.x + value.translation.width,
                    y: start.y + value.translation.height
                )

                lamps[index].position = resolvedLampPosition(for: index, proposed: nextPoint, in: size)
                dragStartPositions[lampID] = nil
            }
    }

    private func clampedWaterBowlPosition(_ point: CGPoint, in size: CGSize) -> CGPoint {
        let verticalRange = lampVerticalRange(in: size)
        let clampedY = min(max(point.y, verticalRange.lowerBound + 8), verticalRange.upperBound)
        let bowlSize = waterBowlMetrics(for: CGPoint(x: point.x, y: clampedY), in: size)
        let horizontalInset = bowlSize.width * 0.48 + 6

        return CGPoint(
            x: min(max(point.x, horizontalInset), size.width - horizontalInset),
            y: clampedY
        )
    }

    private func dragWaterBowlGesture(for bowlID: UUID, in size: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 4, coordinateSpace: .local)
            .onChanged { value in
                guard let index = waterBowls.firstIndex(where: { $0.id == bowlID }) else { return }

                if dragStartWaterBowlPositions[bowlID] == nil {
                    dragStartWaterBowlPositions[bowlID] = waterBowls[index].position
                }

                let start = dragStartWaterBowlPositions[bowlID] ?? waterBowls[index].position
                let nextPoint = CGPoint(
                    x: start.x + value.translation.width,
                    y: start.y + value.translation.height
                )

                waterBowls[index].position = resolvedWaterBowlPosition(for: index, proposed: nextPoint, in: size)
            }
            .onEnded { value in
                guard let index = waterBowls.firstIndex(where: { $0.id == bowlID }) else { return }

                let start = dragStartWaterBowlPositions[bowlID] ?? waterBowls[index].position
                let nextPoint = CGPoint(
                    x: start.x + value.translation.width,
                    y: start.y + value.translation.height
                )

                waterBowls[index].position = resolvedWaterBowlPosition(for: index, proposed: nextPoint, in: size)
                dragStartWaterBowlPositions[bowlID] = nil
            }
    }

    private func clampedIncensePosition(_ point: CGPoint, in size: CGSize) -> CGPoint {
        let verticalRange = lampVerticalRange(in: size)
        let clampedY = min(max(point.y, verticalRange.lowerBound + 8), verticalRange.upperBound)
        let incenseSize = incenseMetrics(for: CGPoint(x: point.x, y: clampedY), in: size)
        let horizontalInset = incenseSize.width * 0.75 + 6

        return CGPoint(
            x: min(max(point.x, horizontalInset), size.width - horizontalInset),
            y: clampedY
        )
    }

    private func dragIncenseGesture(for incenseID: UUID, in size: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 4, coordinateSpace: .local)
            .onChanged { value in
                guard let index = incenseSticks.firstIndex(where: { $0.id == incenseID }) else { return }

                if dragStartIncensePositions[incenseID] == nil {
                    dragStartIncensePositions[incenseID] = incenseSticks[index].position
                }

                let start = dragStartIncensePositions[incenseID] ?? incenseSticks[index].position
                let nextPoint = CGPoint(
                    x: start.x + value.translation.width,
                    y: start.y + value.translation.height
                )

                incenseSticks[index].position = resolvedIncensePosition(for: index, proposed: nextPoint, in: size)
            }
            .onEnded { value in
                guard let index = incenseSticks.firstIndex(where: { $0.id == incenseID }) else { return }

                let start = dragStartIncensePositions[incenseID] ?? incenseSticks[index].position
                let nextPoint = CGPoint(
                    x: start.x + value.translation.width,
                    y: start.y + value.translation.height
                )

                incenseSticks[index].position = resolvedIncensePosition(for: index, proposed: nextPoint, in: size)
                dragStartIncensePositions[incenseID] = nil
            }
    }

    private func toggleLamp(id: UUID) {
        guard let index = lamps.firstIndex(where: { $0.id == id }) else { return }
        lamps[index].isLit.toggle()
    }

    private func fillWaterBowl(id: UUID) {
        guard let index = waterBowls.firstIndex(where: { $0.id == id }) else { return }
        waterBowls[index].isFilled = true
    }

    private func clampAllLampPositions(in size: CGSize) {
        for index in lamps.indices {
            lamps[index].position = resolvedLampPosition(for: index, proposed: lamps[index].position, in: size)
        }
    }

    private func clampAllWaterBowlPositions(in size: CGSize) {
        for index in waterBowls.indices {
            waterBowls[index].position = resolvedWaterBowlPosition(for: index, proposed: waterBowls[index].position, in: size)
        }
    }

    private func clampAllIncensePositions(in size: CGSize) {
        for index in incenseSticks.indices {
            incenseSticks[index].position = resolvedIncensePosition(for: index, proposed: incenseSticks[index].position, in: size)
        }
    }

    private func resolvedLampPosition(for index: Int, proposed: CGPoint, in size: CGSize) -> CGPoint {
        var resolved = clampedLampPosition(proposed, in: size)

        for _ in 0..<2 {
            var adjusted = resolved

            for otherIndex in lamps.indices where otherIndex != index {
                adjusted = separatedLampPosition(
                    candidate: adjusted,
                    candidateIndex: index,
                    otherIndex: otherIndex,
                    in: size
                )
            }

            let clamped = clampedLampPosition(adjusted, in: size)
            if hypot(clamped.x - resolved.x, clamped.y - resolved.y) < 0.5 {
                resolved = clamped
                break
            }
            resolved = clamped
        }

        return resolved
    }

    private func separatedLampPosition(candidate: CGPoint, candidateIndex: Int, otherIndex: Int, in size: CGSize) -> CGPoint {
        let candidateSize = lampMetrics(for: candidate, in: size)
        let otherPosition = lamps[otherIndex].position
        let otherSize = lampMetrics(for: otherPosition, in: size)

        let dx = candidate.x - otherPosition.x
        let dy = candidate.y - otherPosition.y

        let minHorizontal = (candidateSize.width + otherSize.width) * 0.24
        let minVertical = (candidateSize.height + otherSize.height) * 0.13

        guard abs(dx) < minHorizontal, abs(dy) < minVertical else {
            return candidate
        }

        let pushX: CGFloat
        let pushY: CGFloat

        if abs(dx) >= abs(dy) {
            let directionX: CGFloat = dx == 0 ? (candidateIndex < otherIndex ? -1 : 1) : (dx < 0 ? -1 : 1)
            pushX = directionX * (minHorizontal - abs(dx))
            pushY = 0
        } else {
            let directionY: CGFloat = dy == 0 ? (candidateIndex < otherIndex ? -1 : 1) : (dy < 0 ? -1 : 1)
            pushX = 0
            pushY = directionY * (minVertical - abs(dy))
        }

        return CGPoint(x: candidate.x + pushX, y: candidate.y + pushY)
    }

    private func resolvedWaterBowlPosition(for index: Int, proposed: CGPoint, in size: CGSize) -> CGPoint {
        var resolved = clampedWaterBowlPosition(proposed, in: size)

        for _ in 0..<2 {
            var adjusted = resolved

            for otherIndex in waterBowls.indices where otherIndex != index {
                adjusted = separatedWaterBowlPosition(
                    candidate: adjusted,
                    candidateIndex: index,
                    otherIndex: otherIndex,
                    in: size
                )
            }

            let clamped = clampedWaterBowlPosition(adjusted, in: size)
            if hypot(clamped.x - resolved.x, clamped.y - resolved.y) < 0.5 {
                resolved = clamped
                break
            }
            resolved = clamped
        }

        return resolved
    }

    private func separatedWaterBowlPosition(candidate: CGPoint, candidateIndex: Int, otherIndex: Int, in size: CGSize) -> CGPoint {
        let candidateSize = waterBowlMetrics(for: candidate, in: size)
        let otherPosition = waterBowls[otherIndex].position
        let otherSize = waterBowlMetrics(for: otherPosition, in: size)

        let dx = candidate.x - otherPosition.x
        let dy = candidate.y - otherPosition.y

        let minHorizontal = (candidateSize.width + otherSize.width) * 0.34
        let minVertical = (candidateSize.height + otherSize.height) * 0.18

        guard abs(dx) < minHorizontal, abs(dy) < minVertical else {
            return candidate
        }

        if abs(dx) >= abs(dy) {
            let directionX: CGFloat = dx == 0 ? (candidateIndex < otherIndex ? -1 : 1) : (dx < 0 ? -1 : 1)
            return CGPoint(x: candidate.x + directionX * (minHorizontal - abs(dx)), y: candidate.y)
        } else {
            let directionY: CGFloat = dy == 0 ? (candidateIndex < otherIndex ? -1 : 1) : (dy < 0 ? -1 : 1)
            return CGPoint(x: candidate.x, y: candidate.y + directionY * (minVertical - abs(dy)))
        }
    }

    private func resolvedIncensePosition(for index: Int, proposed: CGPoint, in size: CGSize) -> CGPoint {
        var resolved = clampedIncensePosition(proposed, in: size)

        for _ in 0..<2 {
            var adjusted = resolved

            for otherIndex in incenseSticks.indices where otherIndex != index {
                adjusted = separatedIncensePosition(
                    candidate: adjusted,
                    candidateIndex: index,
                    otherIndex: otherIndex,
                    in: size
                )
            }

            let clamped = clampedIncensePosition(adjusted, in: size)
            if hypot(clamped.x - resolved.x, clamped.y - resolved.y) < 0.5 {
                resolved = clamped
                break
            }
            resolved = clamped
        }

        return resolved
    }

    private func separatedIncensePosition(candidate: CGPoint, candidateIndex: Int, otherIndex: Int, in size: CGSize) -> CGPoint {
        let candidateSize = incenseMetrics(for: candidate, in: size)
        let otherPosition = incenseSticks[otherIndex].position
        let otherSize = incenseMetrics(for: otherPosition, in: size)

        let dx = candidate.x - otherPosition.x
        let dy = candidate.y - otherPosition.y

        let minHorizontal = (candidateSize.width + otherSize.width) * 0.8
        let minVertical = (candidateSize.height + otherSize.height) * 0.18

        guard abs(dx) < minHorizontal, abs(dy) < minVertical else {
            return candidate
        }

        if abs(dx) >= abs(dy) {
            let directionX: CGFloat = dx == 0 ? (candidateIndex < otherIndex ? -1 : 1) : (dx < 0 ? -1 : 1)
            return CGPoint(x: candidate.x + directionX * (minHorizontal - abs(dx)), y: candidate.y)
        } else {
            let directionY: CGFloat = dy == 0 ? (candidateIndex < otherIndex ? -1 : 1) : (dy < 0 ? -1 : 1)
            return CGPoint(x: candidate.x, y: candidate.y + directionY * (minVertical - abs(dy)))
        }
    }
}

private struct OfferingLamp: Identifiable {
    let id = UUID()
    var position: CGPoint
    var isLit = false
    var motionSeed = Double.random(in: 0...1)
}

private struct OfferingWaterBowl: Identifiable {
    let id = UUID()
    var position: CGPoint
    var isFilled = false
    var motionSeed = Double.random(in: 0...1)
}

private enum OfferingBackground: String, CaseIterable, Identifiable {
    case buddha
    case vajraYogini
    case guruRinpoche
    case amitabha
    case greenTara
    case whiteTara

    var id: String { rawValue }

    var assetName: String {
        switch self {
        case .buddha:
            return "BuddhaS"
        case .vajraYogini:
            return "VajraYogini 1"
        case .guruRinpoche:
            return "GuruRinpoche 1"
        case .amitabha:
            return "Amitabha"
        case .greenTara:
            return "Green Tara"
        case .whiteTara:
            return "White Tara"
        }
    }

    var menuTitle: String {
        switch self {
        case .buddha:
            return "Buddha"
        case .vajraYogini:
            return "Vajra Yogini"
        case .guruRinpoche:
            return "Guru Rinpoche"
        case .amitabha:
            return "Amitabha"
        case .greenTara:
            return "Green Tara"
        case .whiteTara:
            return "White Tara"
        }
    }
}

private struct OfferingIncense: Identifiable {
    let id = UUID()
    var position: CGPoint
    var motionSeed = Double.random(in: 0...1)
}

private struct MovableWaterBowlView: View {
    let size: CGSize
    let isFilled: Bool
    let motionSeed: Double

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 24.0, paused: !isFilled)) { context in
            let phase = context.date.timeIntervalSinceReferenceDate
            let shimmer = sin(phase * (0.9 + motionSeed * 0.12) + motionSeed * 6.3)
            let ripple = sin(phase * (1.35 + motionSeed * 0.1) + motionSeed * 9.1)

            ZStack {
                Image("waterbowl")
                    .resizable()
                    .renderingMode(.original)
                    .scaledToFit()
                    .frame(width: size.width, height: size.height)

                if isFilled {
                    Ellipse()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.78, green: 0.92, blue: 1.0).opacity(0.78),
                                    Color(red: 0.58, green: 0.82, blue: 0.98).opacity(0.56)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: size.width * 0.58, height: size.height * 0.11)
                        .scaleEffect(x: 1.0 + ripple * 0.015, y: 1.0 + shimmer * 0.02)
                        .offset(y: -size.height * 0.09)
                        .blur(radius: 0.4)
                        .overlay {
                            Ellipse()
                                .stroke(Color.white.opacity(0.28), lineWidth: 1)
                                .frame(width: size.width * 0.52, height: size.height * 0.05)
                                .offset(y: -size.height * 0.11)
                                .opacity(0.6 + shimmer * 0.08)
                        }
                        .shadow(color: Color(red: 0.62, green: 0.84, blue: 1.0).opacity(0.16), radius: 6, x: 0, y: -1)
                        .allowsHitTesting(false)
                }
            }
            .frame(width: size.width, height: size.height)
            .contentShape(WaterBowlHitShape())
        }
    }
}

private struct MovableLampView: View {
    let assetName: String
    let size: CGSize
    let motionSeed: Double

    private var isLit: Bool {
        assetName == "butterlamp"
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 24.0, paused: !isLit)) { context in
            let phase = context.date.timeIntervalSinceReferenceDate
            let flameSwayA = sin(phase * (1.55 + motionSeed * 0.75) + motionSeed * 8.2)
            let flameSwayB = sin(phase * (2.35 + motionSeed * 0.95) + motionSeed * 13.7)
            let flameLift = sin(phase * (1.85 + motionSeed * 0.6) + motionSeed * 5.4)
            let glowDrift = sin(phase * (0.92 + motionSeed * 0.4) + motionSeed * 10.4)
            let glowPulse = sin(phase * (1.18 + motionSeed * 0.55) + motionSeed * 6.1)
            let motionEnvelope = 0.88 + ((sin(phase * (0.24 + motionSeed * 0.08) + motionSeed * 4.9) + 1) * 0.5) * 0.28
            let flickerPulse = pow(max(0, sin(phase * (3.8 + motionSeed * 1.4) + motionSeed * 17.0)), 8)

            let flameRotation = (flameSwayA * 0.68 + flameSwayB * 0.20) * motionEnvelope + flickerPulse * 0.14
            let flameTwist = (flameSwayB * 7.1 + flameSwayA * 2.25) * motionEnvelope + flickerPulse * 1.1
            let flamePivot = (flameLift * 0.52 + flameSwayA * 0.18) * (0.92 + flickerPulse * 0.22)
            let flameScaleX = 1.0 + flameSwayB * 0.024 * motionEnvelope - flickerPulse * 0.01
            let flameScaleY = 1.0 - flameLift * 0.009 * motionEnvelope
            let flameFlickerSettle = flickerPulse * 0.45
            let flameOpacity = 0.98 + glowPulse * 0.012 + flickerPulse * 0.05

            ZStack {
                Color.clear
                    .frame(width: size.width + 6, height: size.height + 8)

                if isLit {
                    CandleGlowLayer(
                        size: size,
                        drift: glowDrift,
                        pulse: glowPulse
                    )
                }

                if isLit {
                    Image("butterlamp")
                        .resizable()
                        .renderingMode(.original)
                        .scaledToFit()
                        .frame(width: size.width, height: size.height)
                        .colorMultiply(Color(red: 1.0, green: 0.95, blue: 0.82))
                        .mask(FlameSuppressedMask(size: size))
                        .shadow(
                            color: Color(red: 1.0, green: 0.82, blue: 0.42).opacity(0.18),
                            radius: 22,
                            x: 0,
                            y: 8
                        )
                } else {
                    Image(assetName)
                        .resizable()
                        .renderingMode(.original)
                        .scaledToFit()
                        .frame(width: size.width, height: size.height)
                        .colorMultiply(Color(red: 1.0, green: 0.94, blue: 0.80))
                        .shadow(
                            color: Color(red: 1.0, green: 0.82, blue: 0.42).opacity(0.04),
                            radius: 10,
                            x: 0,
                            y: 8
                        )
                }

                if isLit {
                    Image("butterlamp")
                        .resizable()
                        .renderingMode(.original)
                        .scaledToFit()
                        .frame(width: size.width, height: size.height)
                        .mask(FlameIsolatedMask(size: size))
                        .colorMultiply(Color(red: 1.0, green: 0.94, blue: 0.78))
                        .rotationEffect(.degrees(flameRotation), anchor: UnitPoint(x: 0.5, y: 0.92))
                        .rotation3DEffect(
                            .degrees(flameTwist),
                            axis: (x: 0, y: 1, z: 0),
                            anchor: UnitPoint(x: 0.5, y: 0.92),
                            perspective: 0.7
                        )
                        .rotation3DEffect(
                            .degrees(flamePivot),
                            axis: (x: 1, y: 0, z: 0),
                            anchor: UnitPoint(x: 0.5, y: 0.92),
                            perspective: 0.45
                        )
                        .scaleEffect(
                            x: flameScaleX,
                            y: flameScaleY,
                            anchor: UnitPoint(x: 0.5, y: 0.92)
                        )
                        .offset(y: 0.9 + flameFlickerSettle)
                        .shadow(
                            color: Color(red: 1.0, green: 0.82, blue: 0.34).opacity(0.12),
                            radius: 5,
                            x: 0,
                            y: 0
                        )
                        .opacity(flameOpacity)
                        .allowsHitTesting(false)
                }
            }
            .contentShape(LampHitShape())
        }
    }
}

private struct MovableIncenseView: View {
    let size: CGSize
    let motionSeed: Double

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 24.0)) { context in
            let phase = context.date.timeIntervalSinceReferenceDate

            ZStack(alignment: .bottom) {
                Image("butterincense")
                    .resizable()
                    .renderingMode(.original)
                    .scaledToFit()
                    .frame(width: size.width, height: size.height)

                ForEach(0..<2, id: \.self) { layer in
                    IncenseSmokeLayerView(
                        size: size,
                        phase: phase,
                        motionSeed: motionSeed,
                        layerIndex: layer
                    )
                }
            }
            .frame(width: size.width, height: size.height)
            .contentShape(IncenseHitShape())
        }
    }
}

private struct IncenseSmokeLayerView: View {
    let size: CGSize
    let phase: TimeInterval
    let motionSeed: Double
    let layerIndex: Int

    var body: some View {
        let layer = Double(layerIndex)
        let cycle = positiveRemainder(
            phase * (0.095 + motionSeed * 0.018 + layer * 0.007) + motionSeed * 0.53 + layer * 0.31,
            1.0
        )
        let rise = CGFloat(cycle) * size.height * (0.072 + CGFloat(layer) * 0.012)
        let swayA = sin(phase * (0.86 + layer * 0.11 + motionSeed * 0.09) + motionSeed * 7.2 + layer * 0.8)
        let swayB = sin(phase * (1.22 + layer * 0.08 + motionSeed * 0.06) + motionSeed * 11.4 + layer * 1.1)
        let offsetX = (swayA * 0.75 + swayB * 0.35) * size.width * (0.008 + CGFloat(layer) * 0.002 + CGFloat(cycle) * 0.007)
        let rotation = (swayA * 0.5 + swayB * 0.25) * (0.55 + CGFloat(cycle) * 0.75)
        let twist = (swayB * 3.0 + swayA * 0.95) * (0.52 + CGFloat(cycle) * 0.55)
        let stretchY = 1.0 + CGFloat(cycle) * (0.12 + CGFloat(layer) * 0.03)
        let stretchX = 1.0 - CGFloat(cycle) * (0.024 + CGFloat(layer) * 0.008)
        let bellFade = pow(max(0, sin(cycle * .pi)), 1.45)
        let fade = bellFade * (0.26 - CGFloat(layer) * 0.04)

        return Image("butterincense2")
            .resizable()
            .renderingMode(.original)
            .scaledToFit()
            .frame(width: size.width, height: size.height)
            .mask(IncenseHelperSmokeIsolatedMask(size: size))
            .rotationEffect(.degrees(rotation), anchor: UnitPoint(x: 0.47, y: 0.88))
            .rotation3DEffect(
                .degrees(twist),
                axis: (x: 0, y: 1, z: 0),
                anchor: UnitPoint(x: 0.47, y: 0.88),
                perspective: 0.78
            )
            .scaleEffect(x: stretchX, y: stretchY, anchor: UnitPoint(x: 0.47, y: 0.88))
            .offset(x: offsetX - size.width * 0.008, y: -rise + size.height * 0.008)
            .opacity(fade)
            .blur(radius: CGFloat(layerIndex) * 0.45 + CGFloat(cycle) * 0.55)
            .allowsHitTesting(false)
    }

    private func positiveRemainder(_ value: Double, _ modulus: Double) -> Double {
        let remainder = value.truncatingRemainder(dividingBy: modulus)
        return remainder >= 0 ? remainder : remainder + modulus
    }
}

private struct LampHitShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        let bowlRect = CGRect(
            x: rect.midX - rect.width * 0.27,
            y: rect.height * 0.48,
            width: rect.width * 0.54,
            height: rect.height * 0.24
        )

        let stemRect = CGRect(
            x: rect.midX - rect.width * 0.09,
            y: rect.height * 0.67,
            width: rect.width * 0.18,
            height: rect.height * 0.18
        )

        let flameRect = CGRect(
            x: rect.midX - rect.width * 0.08,
            y: rect.height * 0.08,
            width: rect.width * 0.16,
            height: rect.height * 0.42
        )

        path.addEllipse(in: bowlRect)
        path.addRoundedRect(in: stemRect, cornerSize: CGSize(width: rect.width * 0.04, height: rect.width * 0.04))
        path.addRoundedRect(in: flameRect, cornerSize: CGSize(width: rect.width * 0.06, height: rect.width * 0.06))

        return path
    }
}

private struct WaterBowlHitShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        let bowlRect = CGRect(
            x: rect.midX - rect.width * 0.34,
            y: rect.height * 0.28,
            width: rect.width * 0.68,
            height: rect.height * 0.42
        )

        let stemRect = CGRect(
            x: rect.midX - rect.width * 0.14,
            y: rect.height * 0.62,
            width: rect.width * 0.28,
            height: rect.height * 0.26
        )

        path.addEllipse(in: bowlRect)
        path.addRoundedRect(in: stemRect, cornerSize: CGSize(width: rect.width * 0.06, height: rect.width * 0.06))

        return path
    }
}

private struct IncenseHitShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        let stickRect = CGRect(
            x: rect.midX - rect.width * 0.16,
            y: rect.height * 0.12,
            width: rect.width * 0.32,
            height: rect.height * 0.82
        )

        path.addRoundedRect(in: stickRect, cornerSize: CGSize(width: rect.width * 0.08, height: rect.width * 0.08))

        return path
    }
}

private struct IncenseSmokeShapeMask: View {
    let size: CGSize

    var body: some View {
        ZStack {
            Color.black

            Capsule(style: .continuous)
                .foregroundStyle(.white)
                .frame(width: size.width * 0.28, height: size.height * 0.33)
                .offset(x: -size.width * 0.07, y: -size.height * 0.27)

            Capsule(style: .continuous)
                .foregroundStyle(.white)
                .frame(width: size.width * 0.18, height: size.height * 0.14)
                .offset(x: -size.width * 0.015, y: -size.height * 0.41)

            RoundedRectangle(cornerRadius: size.width * 0.05, style: .continuous)
                .foregroundStyle(.black)
                .frame(width: size.width * 0.10, height: size.height * 0.07)
                .offset(x: size.width * 0.13, y: -size.height * 0.40)
                .blendMode(.destinationOut)
        }
        .compositingGroup()
        .blur(radius: size.width * 0.016)
    }
}

private struct IncenseHelperSmokeIsolatedMask: View {
    let size: CGSize

    var body: some View {
        IncenseSmokeShapeMask(size: size)
    }
}

private struct FlameShapeMask: View {
    let size: CGSize

    var body: some View {
        ZStack {
            Capsule(style: .continuous)
                .frame(width: size.width * 0.12, height: size.height * 0.34)
                .offset(y: -size.height * 0.31)

            Capsule(style: .continuous)
                .frame(width: size.width * 0.072, height: size.height * 0.13)
                .offset(y: -size.height * 0.14)
        }
        .blur(radius: size.width * 0.012)
    }
}

private struct FlameIsolatedMask: View {
    let size: CGSize

    var body: some View {
        FlameShapeMask(size: size)
    }
}

private struct FlameSuppressedMask: View {
    let size: CGSize

    var body: some View {
        Rectangle()
            .fill(.white)
            .overlay {
                FlameShapeMask(size: size)
                    .foregroundStyle(.black)
                    .blendMode(.destinationOut)
            }
            .compositingGroup()
    }
}

private struct CandleGlowLayer: View {
    let size: CGSize
    let drift: Double
    let pulse: Double

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(red: 1.0, green: 0.90, blue: 0.58).opacity(0.28),
                            Color(red: 1.0, green: 0.73, blue: 0.22).opacity(0.12),
                            .clear
                        ],
                        center: .center,
                        startRadius: 4,
                        endRadius: size.width * 0.64
                    )
                )
                .frame(width: size.width * 1.24, height: size.width * 1.24)
                .blur(radius: 20)
                .scaleEffect(1.0 + pulse * 0.038)
                .offset(x: drift * 5.5, y: -size.height * 0.33 + pulse * -2.4)

            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(0.16),
                            Color(red: 1.0, green: 0.86, blue: 0.48).opacity(0.10),
                            .clear
                        ],
                        center: .center,
                        startRadius: 2,
                        endRadius: size.width * 0.42
                    )
                )
                .frame(width: size.width * 0.8, height: size.width * 0.96)
                .blur(radius: 12)
                .scaleEffect(1.0 + pulse * 0.022)
                .offset(x: drift * -3.2, y: -size.height * 0.3)
        }
        .allowsHitTesting(false)
    }
}

#Preview {
    NavigationStack {
        LightOfferingView()
    }
}
