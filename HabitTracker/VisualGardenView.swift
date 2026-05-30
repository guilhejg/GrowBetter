import SwiftUI
import SwiftData

struct VisualGardenView: View {
    @Query(sort: \HTHabit.createdAt, order: .forward)
    private var habits: [HTHabit]

    @Query(sort: \HTHabitLog.date, order: .forward)
    private var allLogs: [HTHabitLog]

    @State private var selectedHabitKey = ""

    var body: some View {
        ZStack {
            HTAppBackground()

            if habits.isEmpty {
                emptyState
            } else {
                TabView(selection: pageSelection) {
                    ForEach(habits, id: \.persistentModelID) { habit in
                        HabitGardenPageView(
                            habit: habit,
                            habitLogs: logs(for: habit),
                            pageText: pageText(for: habit)
                        )
                        .tag(habitGardenKey(habit))
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .ignoresSafeArea()
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .preferredColorScheme(.dark)
        .onAppear(perform: selectFirstHabitIfNeeded)
        .onChange(of: habits) { _, _ in
            selectFirstHabitIfNeeded()
        }
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "leaf.circle.fill")
                .font(.system(size: 52, weight: .bold))
                .foregroundStyle(Color(red: 0.39, green: 0.88, blue: 0.28))

            Text("Crie um hábito")
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(.white)

            Text("Cada hábito terá seu próprio jardim.")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white.opacity(0.62))
                .multilineTextAlignment(.center)
        }
        .padding(24)
    }

    private var pageSelection: Binding<String> {
        Binding(
            get: {
                if habits.contains(where: { habitGardenKey($0) == selectedHabitKey }) {
                    return selectedHabitKey
                }
                return habits.first.map(habitGardenKey) ?? ""
            },
            set: { selectedHabitKey = $0 }
        )
    }

    private func selectFirstHabitIfNeeded() {
        guard let first = habits.first else {
            selectedHabitKey = ""
            return
        }

        if habits.contains(where: { habitGardenKey($0) == selectedHabitKey }) == false {
            selectedHabitKey = habitGardenKey(first)
        }
    }

    private func logs(for habit: HTHabit) -> [HTHabitLog] {
        let habitID = habit.persistentModelID
        return allLogs.filter { $0.habit.persistentModelID == habitID }
    }

    private func pageText(for habit: HTHabit) -> String {
        guard let index = habits.firstIndex(where: { $0.persistentModelID == habit.persistentModelID }) else {
            return ""
        }
        return "\(index + 1)/\(habits.count)"
    }
}

private struct HabitGardenPageView: View {
    let habit: HTHabit
    let habitLogs: [HTHabitLog]
    let pageText: String

    @AppStorage("appearance.uiScale") private var uiScale: Double = 0.85

    @State private var garden = HabitGardenState()
    @State private var selectedCoordinate: GardenCoordinate?
    @State private var cameraOffset: CGSize = .zero
    @State private var lastCameraOffset: CGSize = .zero
    @State private var zoom: CGFloat = 1.65
    @State private var lastZoom: CGFloat = 1.65
    @State private var viewportSize: CGSize = .zero
    @State private var didCenterCamera = false
    @State private var toast: String?

    private let gridCount = 32
    private let startingUnlockedTiles = 4
    private let tilesUnlockedPerDay = 4
    private let minimumZoom: CGFloat = 1.65
    private let maximumZoom: CGFloat = 4.80

    private var accent: Color {
        Color(hex: habit.colorHex)
    }

    private var scale: CGFloat {
        CGFloat(min(max(uiScale, 0.75), 0.92))
    }

    private func scaled(_ value: CGFloat) -> CGFloat {
        value * scale
    }

    private var tileSize: CGFloat {
        scaled(28)
    }

    private var gridHalf: Int {
        gridCount / 2
    }

    private var worldSize: CGFloat {
        CGFloat(gridCount) * tileSize
    }

    private var worldMargin: CGFloat {
        tileSize * 1.25
    }

    private var storageKey: String {
        "habitGarden.\(habitGardenKey(habit)).state"
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color(red: 0.03, green: 0.07, blue: 0.04)
                    .ignoresSafeArea()

                gardenCanvas

                if let toast {
                    VStack {
                        Spacer()
                        Text(toast)
                            .font(.system(size: scaled(14), weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, scaled(16))
                            .padding(.vertical, scaled(10))
                            .background(Color.black.opacity(0.76))
                            .clipShape(Capsule())
                            .padding(.bottom, scaled(156))
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                topOverlay(viewport: geo.size, safeTop: geo.safeAreaInsets.top)

                rightActionRail(safeTop: geo.safeAreaInsets.top)

                VStack(spacing: 0) {
                    Spacer()

                    bottomDock
                        .padding(.bottom, geo.safeAreaInsets.bottom + scaled(74))
                        .contentShape(Rectangle())
                }
            }
            .onAppear {
                viewportSize = geo.size
                loadGarden()
                claimDailyRewardIfNeeded()
                centerCamera(in: geo.size, animated: false)
            }
            .onChange(of: geo.size) { _, newSize in
                viewportSize = newSize
                centerCamera(in: newSize, animated: false, force: true)
            }
            .onChange(of: garden) { _, _ in
                saveGarden()
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .preferredColorScheme(.dark)
    }

    private var gardenCanvas: some View {
        Canvas { context, _ in
            drawBoard(context: &context)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .coordinateSpace(name: "gardenViewport")
        .contentShape(Rectangle())
        .clipped()
        .simultaneousGesture(tapGesture())
        .simultaneousGesture(dragGesture())
        .simultaneousGesture(zoomGesture())
    }

    private func drawBoard(context: inout GraphicsContext) {
        let selectedStroke = Color.white.opacity(0.95)
        let lockedSelectedStroke = Color(red: 0.98, green: 0.72, blue: 0.28)
        let visualTileSize = tileSize * zoom
        let unlockedCoordinates = unlockedCoordinateSet

        for row in 0..<gridCount {
            for col in 0..<gridCount {
                let x = cameraOffset.width + CGFloat(col) * visualTileSize
                let y = cameraOffset.height + CGFloat(row) * visualTileSize
                let rect = CGRect(x: x, y: y, width: visualTileSize, height: visualTileSize)
                let coordinate = GardenCoordinate(x: col - gridHalf, y: row - gridHalf)
                let isSelected = coordinate == selectedCoordinate
                let unlocked = unlockedCoordinates.contains(coordinate)
                let assetName = tileAssetName(row: row, col: col, coordinate: coordinate, unlocked: unlocked)

                context.fill(
                    Path(rect),
                    with: .color(tileFallbackColor(row: row, col: col, coordinate: coordinate, unlocked: unlocked))
                )
                context.draw(Image(assetName).interpolation(.none), in: rect)

                if unlocked == false {
                    context.fill(Path(rect), with: .color(Color.black.opacity(0.12)))
                }

                if isSelected {
                    context.fill(
                        Path(roundedRect: rect.insetBy(dx: 3, dy: 3), cornerRadius: max(4, visualTileSize * 0.14)),
                        with: .color(Color.black.opacity(0.12))
                    )
                    context.stroke(
                        Path(roundedRect: rect.insetBy(dx: 2, dy: 2), cornerRadius: max(4, visualTileSize * 0.14)),
                        with: .color(unlocked ? selectedStroke : lockedSelectedStroke),
                        lineWidth: 3
                    )
                }
            }
        }

        drawUnlockedTileBorders(context: &context, visualTileSize: visualTileSize, unlockedCoordinates: unlockedCoordinates)

        for plant in garden.plants {
            drawPlant(plant, context: &context)
        }
    }

    private func tileAssetName(row: Int, col: Int, coordinate: GardenCoordinate, unlocked: Bool) -> String {
        if unlocked == false { return "grass_locked_64" }
        if plant(at: coordinate) != nil { return "soil_64" }
        return (row + col).isMultiple(of: 2) ? "grass_light_64" : "grass_dark_64"
    }

    private func tileFallbackColor(row: Int, col: Int, coordinate: GardenCoordinate, unlocked: Bool) -> Color {
        if unlocked == false {
            return Color(red: 0.02, green: 0.14, blue: 0.08)
        }

        if plant(at: coordinate) != nil {
            return Color(red: 0.38, green: 0.22, blue: 0.12)
        }

        return (row + col).isMultiple(of: 2)
            ? Color(red: 0.56, green: 0.78, blue: 0.28)
            : Color(red: 0.16, green: 0.58, blue: 0.24)
    }

    private func drawUnlockedTileBorders(context: inout GraphicsContext, visualTileSize: CGFloat, unlockedCoordinates: Set<GardenCoordinate>) {
        for coordinate in unlockedCoordinates {
            let col = coordinate.x + gridHalf
            let row = coordinate.y + gridHalf
            let rect = CGRect(
                x: cameraOffset.width + CGFloat(col) * visualTileSize,
                y: cameraOffset.height + CGFloat(row) * visualTileSize,
                width: visualTileSize,
                height: visualTileSize
            )

            context.stroke(
                Path(rect.insetBy(dx: 1, dy: 1)),
                with: .color(Color.white.opacity(0.08)),
                lineWidth: 1
            )
        }
    }

    private func drawPlant(_ plant: HabitGardenPlant, context: inout GraphicsContext) {
        let col = plant.x + gridHalf
        let row = plant.y + gridHalf
        guard col >= 0, col < gridCount, row >= 0, row < gridCount else { return }

        let visualTileSize = tileSize * zoom
        let origin = CGPoint(
            x: cameraOffset.width + CGFloat(col) * visualTileSize,
            y: cameraOffset.height + CGFloat(row) * visualTileSize
        )
        let rect = CGRect(x: origin.x, y: origin.y, width: visualTileSize, height: visualTileSize)
        let center = CGPoint(x: rect.midX, y: rect.midY)

        let shadowRect = CGRect(
            x: center.x - visualTileSize * 0.34,
            y: center.y + visualTileSize * 0.18,
            width: visualTileSize * 0.68,
            height: visualTileSize * 0.24
        )
        context.draw(Image("shadow_soft").interpolation(.none), in: shadowRect)

        let assetScale = plant.assetScale
        let plantRect = CGRect(
            x: center.x - visualTileSize * assetScale.width / 2,
            y: center.y - visualTileSize * assetScale.height * 0.62,
            width: visualTileSize * assetScale.width,
            height: visualTileSize * assetScale.height
        )

        context.draw(Image(plant.assetName).interpolation(.none), in: plantRect)

        if plant.isWateredToday(todayOrdinal) {
            let dropRect = CGRect(
                x: rect.minX + visualTileSize * 0.08,
                y: rect.maxY - visualTileSize * 0.34,
                width: visualTileSize * 0.25,
                height: visualTileSize * 0.25
            )
            context.draw(Image("item_water").interpolation(.none), in: dropRect)
        }

        if plant.growthStage >= 4 {
            let sparkleRect = CGRect(
                x: rect.maxX - visualTileSize * 0.34,
                y: rect.minY + visualTileSize * 0.08,
                width: visualTileSize * 0.28,
                height: visualTileSize * 0.28
            )
            context.draw(Image("fx_sparkle_1").interpolation(.none), in: sparkleRect)
        }
    }

    private func tapGesture() -> some Gesture {
        SpatialTapGesture(count: 1, coordinateSpace: .named("gardenViewport"))
            .onEnded { value in
                handleTap(at: value.location)
            }
    }

    private func zoomGesture() -> some Gesture {
        MagnificationGesture()
            .onChanged { value in
                zoom = min(max(lastZoom * value, minimumZoom), maximumZoom)
                if viewportSize != .zero {
                    cameraOffset = clampedOffset(cameraOffset, in: viewportSize)
                    lastCameraOffset = cameraOffset
                }
            }
            .onEnded { _ in
                lastZoom = zoom
                if viewportSize != .zero {
                    cameraOffset = clampedOffset(cameraOffset, in: viewportSize)
                    lastCameraOffset = cameraOffset
                }
            }
    }

    private func dragGesture() -> some Gesture {
        DragGesture(minimumDistance: 8, coordinateSpace: .named("gardenViewport"))
            .onChanged { value in
                guard viewportSize != .zero else { return }
                let proposed = CGSize(
                    width: lastCameraOffset.width + value.translation.width,
                    height: lastCameraOffset.height + value.translation.height
                )
                cameraOffset = clampedOffset(proposed, in: viewportSize)
            }
            .onEnded { _ in
                lastCameraOffset = cameraOffset
            }
    }

    private func handleTap(at location: CGPoint) {
        guard let coordinate = coordinate(at: location) else { return }
        withAnimation(.spring(response: 0.22, dampingFraction: 0.9)) {
            selectedCoordinate = coordinate
        }
    }

    private func coordinate(at point: CGPoint) -> GardenCoordinate? {
        let contentX = (point.x - cameraOffset.width) / zoom
        let contentY = (point.y - cameraOffset.height) / zoom
        guard contentX >= 0, contentY >= 0, contentX < worldSize, contentY < worldSize else { return nil }

        let col = Int(contentX / tileSize)
        let row = Int(contentY / tileSize)
        return GardenCoordinate(x: col - gridHalf, y: row - gridHalf)
    }

    private func topOverlay(viewport: CGSize, safeTop: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: scaled(10)) {
            HStack(alignment: .top, spacing: scaled(10)) {
                gardenStatusCard
                    .frame(width: scaled(170))

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: scaled(8)) {
                        resourceChip(asset: "item_water", value: garden.water, accessibilityLabel: "Água", color: Color(red: 0.28, green: 0.66, blue: 1.0))
                        resourceChip(asset: "item_sun", value: garden.sun, accessibilityLabel: "Luz", color: .yellow)
                        resourceChip(asset: "item_fertilizer", value: garden.fertilizer, accessibilityLabel: "Adubo", color: Color(red: 0.84, green: 0.58, blue: 0.26))
                        resourceChip(systemIcon: "circle.hexagongrid.fill", value: garden.coins, accessibilityLabel: "Moedas", color: Color(red: 0.98, green: 0.78, blue: 0.22))
                    }
                    .padding(.trailing, scaled(4))
                }

                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                        zoom = minimumZoom
                        lastZoom = zoom
                        centerCamera(in: viewport, animated: true, force: true)
                    }
                } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: scaled(20), weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: scaled(48), height: scaled(48))
                        .background(Color.black.opacity(0.66))
                        .clipShape(Circle())
                        .overlay(Circle().strokeBorder(Color.white.opacity(0.12), lineWidth: 1))
                }
                .buttonStyle(.plain)
            }

            nextRingCard
                .frame(width: scaled(146))
        }
        .padding(.horizontal, scaled(12))
        .padding(.top, safeTop + scaled(8))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var gardenStatusCard: some View {
        HStack(spacing: scaled(10)) {
            ZStack {
                RoundedRectangle(cornerRadius: scaled(13), style: .continuous)
                    .fill(accent.opacity(0.22))
                    .frame(width: scaled(54), height: scaled(54))

                Image("agabloom_sprout")
                    .resizable()
                    .interpolation(.none)
                    .scaledToFit()
                    .frame(width: scaled(42), height: scaled(42))
            }

            VStack(alignment: .leading, spacing: scaled(5)) {
                Text("Meu Jardim")
                    .font(.system(size: scaled(15), weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)

                Text("Jardim \(pageText)")
                    .font(.system(size: scaled(12), weight: .bold))
                    .foregroundStyle(.white.opacity(0.62))

                HStack(spacing: scaled(8)) {
                    ProgressView(value: Double(unlockedTileCount), total: Double(totalTileCount))
                        .tint(accent)
                        .frame(width: scaled(58))

                    Text("Dia \(gardenProgressDay)")
                        .font(.system(size: scaled(11), weight: .bold))
                        .foregroundStyle(.white.opacity(0.82))
                }
            }
        }
        .padding(scaled(10))
        .background(Color.black.opacity(0.68))
        .clipShape(RoundedRectangle(cornerRadius: scaled(20), style: .continuous))
        .overlay(cardStroke(scaled(20)))
    }

    private var nextRingCard: some View {
        HStack(spacing: scaled(10)) {
            Image(systemName: "sprout.fill")
                .font(.system(size: scaled(24), weight: .bold))
                .foregroundStyle(accent)
                .frame(width: scaled(34))

            VStack(alignment: .leading, spacing: scaled(5)) {
                Text("Próximo anel")
                    .font(.system(size: scaled(14), weight: .bold))
                    .foregroundStyle(.white)

                Text(nextRingText)
                    .font(.system(size: scaled(12), weight: .semibold))
                    .foregroundStyle(.white.opacity(0.66))

                ProgressView(value: nextRingProgress)
                    .tint(Color(red: 1.0, green: 0.76, blue: 0.24))
                    .frame(width: scaled(74))
            }
        }
        .padding(scaled(10))
        .background(Color.black.opacity(0.66))
        .clipShape(RoundedRectangle(cornerRadius: scaled(18), style: .continuous))
        .overlay(cardStroke(scaled(18)))
    }

    private func resourceChip(asset: String? = nil, systemIcon: String? = nil, value: Int, accessibilityLabel: String, color: Color) -> some View {
        HStack(spacing: scaled(5)) {
            if let asset {
                Image(asset)
                    .resizable()
                    .interpolation(.none)
                    .scaledToFit()
                    .frame(width: scaled(17), height: scaled(17))
            } else if let systemIcon {
                Image(systemName: systemIcon)
                    .font(.system(size: scaled(12), weight: .bold))
                    .foregroundStyle(color)
            }

            Text("\(value)")
                .font(.system(size: scaled(12), weight: .bold))
                .monospacedDigit()
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.65)
        }
        .accessibilityLabel("\(accessibilityLabel): \(value)")
        .frame(width: scaled(70), height: scaled(44))
        .background(Color.black.opacity(0.66))
        .clipShape(Capsule())
        .overlay(Capsule().strokeBorder(Color.white.opacity(0.12), lineWidth: 1))
    }

    private func rightActionRail(safeTop: CGFloat) -> some View {
        VStack(spacing: scaled(10)) {
            railButton("Diário", asset: "agabloom_seed")
            railButton("Conquistas", systemIcon: "trophy.fill")
            railButton("Inventário", systemIcon: "shippingbox.fill", showsBadge: true)
        }
        .padding(.trailing, scaled(10))
        .padding(.top, safeTop + scaled(98))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
    }

    private func railButton(_ title: String, asset: String? = nil, systemIcon: String? = nil, showsBadge: Bool = false) -> some View {
        Button {
            showToast("\(title) em breve.")
        } label: {
            VStack(spacing: scaled(5)) {
                ZStack(alignment: .topTrailing) {
                    if let asset {
                        Image(asset)
                            .resizable()
                            .interpolation(.none)
                            .scaledToFit()
                            .frame(width: scaled(29), height: scaled(29))
                    } else if let systemIcon {
                        Image(systemName: systemIcon)
                            .font(.system(size: scaled(24), weight: .bold))
                            .foregroundStyle(Color(red: 1.0, green: 0.72, blue: 0.18))
                    }

                    if showsBadge {
                        Circle()
                            .fill(Color.red)
                            .frame(width: scaled(8), height: scaled(8))
                            .offset(x: scaled(4), y: scaled(-2))
                    }
                }

                Text(title)
                    .font(.system(size: scaled(9), weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(width: scaled(56), height: scaled(64))
            .background(Color.black.opacity(0.64))
            .clipShape(RoundedRectangle(cornerRadius: scaled(14), style: .continuous))
            .overlay(cardStroke(scaled(14)))
        }
        .buttonStyle(.plain)
    }

    private var bottomDock: some View {
        HStack(alignment: .bottom, spacing: scaled(12)) {
            selectedTileCard
                .frame(width: scaled(180))

            Spacer(minLength: scaled(8))

            primaryActionButton
                .frame(width: scaled(150))

            Spacer(minLength: scaled(58))
        }
        .padding(.horizontal, scaled(12))
    }

    private var primaryActionButton: some View {
        Group {
            if let selectedCoordinate {
                if isUnlocked(selectedCoordinate) == false {
                    contextStatus("Bloqueado", icon: "lock.fill", color: Color(red: 0.98, green: 0.72, blue: 0.28))
                } else if selectedPlant == nil {
                    contextButton("Plantar", asset: "agabloom_seed", color: accent) {
                        plantHabit(at: selectedCoordinate)
                    }
                } else if selectedPlant?.growthStage ?? 0 >= 4 {
                    contextButton("Colher", asset: "agabloom_bloom", color: Color(red: 1.0, green: 0.78, blue: 0.22)) {
                        harvestPlant(at: selectedCoordinate)
                    }
                } else if selectedPlant?.isWateredToday(todayOrdinal) == false {
                    contextButton("Regar", asset: "item_water", color: Color(red: 0.28, green: 0.66, blue: 1.0)) {
                        waterPlant(at: selectedCoordinate)
                    }
                } else {
                    contextButton("Adubar", asset: "item_fertilizer", color: Color(red: 0.84, green: 0.58, blue: 0.26)) {
                        fertilizePlant(at: selectedCoordinate)
                    }
                }
            } else {
                contextStatus("Selecione", icon: "hand.tap.fill", color: accent)
            }
        }
    }

    private var contextMenu: some View {
        Group {
            if let selectedCoordinate {
                if isUnlocked(selectedCoordinate) == false {
                    contextStatus("Bloqueado", icon: "lock.fill", color: Color(red: 0.98, green: 0.72, blue: 0.28))
                } else if selectedPlant == nil {
                    HStack(spacing: scaled(8)) {
                        contextButton("Plantar", asset: "agabloom_seed", color: accent) {
                            plantHabit(at: selectedCoordinate)
                        }
                    }
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: scaled(8)) {
                            contextButton("Regar", asset: "item_water", color: Color(red: 0.28, green: 0.66, blue: 1.0)) {
                                waterPlant(at: selectedCoordinate)
                            }
                            contextButton("Luz", asset: "item_sun", color: .yellow) {
                                shinePlant(at: selectedCoordinate)
                            }
                            contextButton("Adubar", asset: "item_fertilizer", color: Color(red: 0.84, green: 0.58, blue: 0.26)) {
                                fertilizePlant(at: selectedCoordinate)
                            }
                            contextButton("Remover", systemIcon: "trash.fill", color: Color(red: 1.0, green: 0.32, blue: 0.28)) {
                                removePlant(at: selectedCoordinate)
                            }
                        }
                    }
                }
            }
        }
        .padding(scaled(8))
        .background(Color.black.opacity(selectedCoordinate == nil ? 0 : 0.52))
        .clipShape(RoundedRectangle(cornerRadius: scaled(20), style: .continuous))
        .overlay(cardStroke(scaled(20)).opacity(selectedCoordinate == nil ? 0 : 1))
    }

    private func contextStatus(_ title: String, icon: String, color: Color) -> some View {
        Label(title, systemImage: icon)
            .font(.system(size: scaled(13), weight: .bold))
            .foregroundStyle(.white)
            .lineLimit(1)
            .padding(.horizontal, scaled(13))
            .padding(.vertical, scaled(10))
            .background(color.opacity(0.24))
            .clipShape(Capsule())
            .overlay(Capsule().strokeBorder(color.opacity(0.55), lineWidth: 1))
    }

    private func contextButton(_ title: String, asset: String? = nil, systemIcon: String? = nil, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: scaled(6)) {
                if let asset {
                    Image(asset)
                        .resizable()
                        .interpolation(.none)
                        .scaledToFit()
                        .frame(width: scaled(18), height: scaled(18))
                } else if let systemIcon {
                    Image(systemName: systemIcon)
                        .font(.system(size: scaled(13), weight: .bold))
                }

                Text(title)
            }
            .font(.system(size: scaled(13), weight: .bold))
            .foregroundStyle(.white)
            .lineLimit(1)
            .padding(.horizontal, scaled(13))
            .padding(.vertical, scaled(10))
            .background(color.opacity(0.26))
            .clipShape(Capsule())
            .overlay(Capsule().strokeBorder(color.opacity(0.55), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private var selectedTileCard: some View {
        HStack(spacing: scaled(12)) {
            ZStack {
                RoundedRectangle(cornerRadius: scaled(13), style: .continuous)
                    .fill(selectedTileAccent.opacity(selectedPlant == nil ? 0.16 : 0.22))
                    .frame(width: scaled(44), height: scaled(44))

                selectedTileIconView
            }

            VStack(alignment: .leading, spacing: scaled(3)) {
                Text(selectedTitle)
                    .font(.system(size: scaled(16), weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)

                Text(selectedSubtitle)
                    .font(.system(size: scaled(12), weight: .medium))
                    .foregroundStyle(.white.opacity(0.62))
                    .lineLimit(2)
                    .minimumScaleFactor(0.82)
            }

            Spacer()
        }
        .padding(scaled(13))
        .background(Color.black.opacity(0.55))
        .clipShape(RoundedRectangle(cornerRadius: scaled(20), style: .continuous))
        .overlay(cardStroke(scaled(20)))
    }

    private var selectedPlant: HabitGardenPlant? {
        guard let selectedCoordinate else { return nil }
        return plant(at: selectedCoordinate)
    }

    private var selectedTileAccent: Color {
        guard let selectedCoordinate, isUnlocked(selectedCoordinate) == false else {
            return accent
        }
        return Color(red: 0.98, green: 0.72, blue: 0.28)
    }

    @ViewBuilder
    private var selectedTileIconView: some View {
        if let selectedCoordinate, isUnlocked(selectedCoordinate) == false {
            Image(systemName: "lock.fill")
                .font(.system(size: scaled(18), weight: .bold))
                .foregroundStyle(selectedTileAccent)
        } else if let selectedPlant {
            Image(selectedPlant.assetName)
                .resizable()
                .interpolation(.none)
                .scaledToFit()
                .frame(width: scaled(34), height: scaled(34))
        } else {
            Image("agabloom_seed")
                .resizable()
                .interpolation(.none)
                .scaledToFit()
                .frame(width: scaled(30), height: scaled(30))
        }
    }

    private var selectedTitle: String {
        if let selectedCoordinate, isUnlocked(selectedCoordinate) == false {
            return "Área bloqueada"
        }
        if selectedPlant != nil {
            return habit.name
        }
        if let selectedCoordinate {
            return "Espaço \(selectedCoordinate.x), \(selectedCoordinate.y)"
        }
        return "Jardim de \(habit.name)"
    }

    private var selectedSubtitle: String {
        if let selectedCoordinate, isUnlocked(selectedCoordinate) == false {
            return lockedAreaText
        }
        if let selectedPlant {
            return selectedPlant.statusText(today: todayOrdinal)
        }
        if selectedCoordinate != nil {
            return "Esse espaço está vazio. Plante uma muda desse hábito."
        }
        return "Deslize para trocar de hábito. Toque em um espaço para cuidar."
    }

    private func cardStroke(_ radius: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: radius, style: .continuous)
            .strokeBorder(Color.white.opacity(0.10), lineWidth: 1)
    }
}

private extension HabitGardenPageView {
    var todayOrdinal: Int {
        Calendar.current.ordinality(of: .day, in: .era, for: .now) ?? 0
    }

    var todayLogsCount: Int {
        habitLogs.filter { Calendar.current.isDateInToday($0.date) }.count
    }

    var completedDaysCount: Int {
        Set(habitLogs.map { Calendar.current.startOfDay(for: $0.date) }).count
    }

    var gardenProgressDay: Int {
        max(completedDaysCount, 1)
    }

    var totalTileCount: Int {
        gridCount * gridCount
    }

    var unlockedTileCount: Int {
        let extraDays = max(gardenProgressDay - 1, 0)
        let count = startingUnlockedTiles + extraDays * tilesUnlockedPerDay
        return min(max(count, startingUnlockedTiles), totalTileCount)
    }

    var nextRingUnlockDay: Int {
        min(totalTileCount / tilesUnlockedPerDay + 1, gardenProgressDay + 1)
    }

    var nextRingText: String {
        let remaining = max(nextRingUnlockDay - gardenProgressDay, 0)
        if unlockedTileCount >= totalTileCount {
            return "Tudo liberado"
        }
        return remaining == 1 ? "Em 1 dia" : "Em \(remaining) dias"
    }

    var nextRingProgress: Double {
        guard unlockedTileCount < totalTileCount else { return 1 }
        let currentRingStart = max(unlockedTileCount - tilesUnlockedPerDay, startingUnlockedTiles)
        let currentStep = max(unlockedTileCount - currentRingStart, 0)
        return min(max(Double(currentStep) / Double(tilesUnlockedPerDay), 0.18), 1)
    }

    var unlockedCoordinateSet: Set<GardenCoordinate> {
        Set(unlockOrder.prefix(unlockedTileCount))
    }

    var unlockOrder: [GardenCoordinate] {
        (-gridHalf..<gridHalf)
            .flatMap { y in
                (-gridHalf..<gridHalf).map { x in
                    GardenCoordinate(x: x, y: y)
                }
            }
            .sorted { lhs, rhs in
                let lhsRing = unlockRing(for: lhs)
                let rhsRing = unlockRing(for: rhs)

                if lhsRing != rhsRing {
                    return lhsRing < rhsRing
                }

                let lhsAngle = atan2(Double(lhs.y) + 0.5, Double(lhs.x) + 0.5)
                let rhsAngle = atan2(Double(rhs.y) + 0.5, Double(rhs.x) + 0.5)

                if lhsAngle != rhsAngle {
                    return lhsAngle < rhsAngle
                }

                if lhs.y != rhs.y {
                    return lhs.y < rhs.y
                }

                return lhs.x < rhs.x
            }
    }

    var lockedAreaText: String {
        guard let selectedCoordinate,
              let index = unlockOrder.firstIndex(of: selectedCoordinate) else {
            return "Esta área ainda está fora do mapa cultivável."
        }

        let unlockDay = index / tilesUnlockedPerDay + 1
        let remainingDays = max(unlockDay - gardenProgressDay, 0)
        return "Libera no dia \(unlockDay). Faltam \(remainingDays) dias concluídos para abrir este bloco."
    }

    func isUnlocked(_ coordinate: GardenCoordinate) -> Bool {
        unlockedCoordinateSet.contains(coordinate)
    }

    func unlockRing(for coordinate: GardenCoordinate) -> Int {
        let dx: Int
        if coordinate.x < -1 {
            dx = -1 - coordinate.x
        } else if coordinate.x > 0 {
            dx = coordinate.x
        } else {
            dx = 0
        }

        let dy: Int
        if coordinate.y < -1 {
            dy = -1 - coordinate.y
        } else if coordinate.y > 0 {
            dy = coordinate.y
        } else {
            dy = 0
        }

        return max(dx, dy)
    }

    func plant(at coordinate: GardenCoordinate) -> HabitGardenPlant? {
        garden.plants.first { $0.x == coordinate.x && $0.y == coordinate.y }
    }

    func plantHabit(at coordinate: GardenCoordinate) {
        guard isUnlocked(coordinate) else {
            showToast("Libere essa área antes de plantar.")
            return
        }

        guard plant(at: coordinate) == nil else {
            showToast("Esse espaço já tem uma planta.")
            return
        }

        garden.plants.append(
            HabitGardenPlant(
                x: coordinate.x,
                y: coordinate.y,
                plantedDay: todayOrdinal,
                wateredDays: [],
                sunPoints: 0,
                fertilizerPoints: 0
            )
        )
        garden.coins = max(garden.coins - 2, 0)
        selectedCoordinate = coordinate
        showToast("Muda plantada.")
    }

    func waterPlant(at coordinate: GardenCoordinate) {
        guard let index = garden.plants.firstIndex(where: { $0.x == coordinate.x && $0.y == coordinate.y }) else {
            showToast("Não há planta para regar.")
            return
        }
        guard garden.water > 0 else {
            showToast("Você está sem água.")
            return
        }
        guard garden.plants[index].isWateredToday(todayOrdinal) == false else {
            showToast("Essa planta já foi regada hoje.")
            return
        }

        garden.water -= 1
        garden.plants[index].wateredDays.append(todayOrdinal)
        showToast("Planta regada.")
    }

    func shinePlant(at coordinate: GardenCoordinate) {
        guard let index = garden.plants.firstIndex(where: { $0.x == coordinate.x && $0.y == coordinate.y }) else {
            showToast("Não há planta para receber luz.")
            return
        }
        guard garden.sun > 0 else {
            showToast("Você está sem luz.")
            return
        }

        garden.sun -= 1
        garden.plants[index].sunPoints += 1
        showToast("Luz aplicada.")
    }

    func fertilizePlant(at coordinate: GardenCoordinate) {
        guard let index = garden.plants.firstIndex(where: { $0.x == coordinate.x && $0.y == coordinate.y }) else {
            showToast("Não há planta para adubar.")
            return
        }
        guard garden.fertilizer > 0 else {
            showToast("Você está sem adubo.")
            return
        }

        garden.fertilizer -= 1
        garden.plants[index].fertilizerPoints += 1
        showToast("Adubo aplicado.")
    }

    func removePlant(at coordinate: GardenCoordinate) {
        guard let index = garden.plants.firstIndex(where: { $0.x == coordinate.x && $0.y == coordinate.y }) else {
            showToast("Não há planta para remover.")
            return
        }

        garden.plants.remove(at: index)
        showToast("Planta removida.")
    }

    func harvestPlant(at coordinate: GardenCoordinate) {
        guard let index = garden.plants.firstIndex(where: { $0.x == coordinate.x && $0.y == coordinate.y }) else {
            showToast("Não há planta para colher.")
            return
        }

        guard garden.plants[index].growthStage >= 4 else {
            showToast("Essa planta ainda não floresceu.")
            return
        }

        garden.coins += 5
        garden.plants.remove(at: index)
        showToast("Colheita feita.")
    }

    func loadGarden() {
        guard
            let data = UserDefaults.standard.data(forKey: storageKey),
            let decoded = try? JSONDecoder().decode(HabitGardenState.self, from: data)
        else {
            garden = HabitGardenState()
            return
        }

        garden = decoded
    }

    func saveGarden() {
        guard let data = try? JSONEncoder().encode(garden) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }

    func claimDailyRewardIfNeeded() {
        guard garden.lastRewardDay != todayOrdinal else { return }
        garden.water += 2 + todayLogsCount
        garden.sun += max(1, todayLogsCount)
        garden.fertilizer += todayLogsCount > 0 ? 1 : 0
        garden.coins += todayLogsCount * 3
        garden.lastRewardDay = todayOrdinal
    }

    func centerCamera(in viewport: CGSize, animated: Bool, force: Bool = false) {
        guard force || didCenterCamera == false else { return }
        didCenterCamera = true

        let centered = clampedOffset(CGSize(
            width: viewport.width / 2 - worldSize * zoom / 2,
            height: viewport.height / 2 - worldSize * zoom / 2
        ), in: viewport)

        if animated {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                cameraOffset = centered
            }
        } else {
            cameraOffset = centered
        }
        lastCameraOffset = centered
    }

    func clampedOffset(_ proposed: CGSize, in viewport: CGSize) -> CGSize {
        let scaledMargin = worldMargin * zoom
        let scaledWorld = worldSize * zoom
        let minX = viewport.width - scaledWorld - scaledMargin
        let maxX = scaledMargin
        let minY = viewport.height - scaledWorld - scaledMargin
        let maxY = scaledMargin

        return CGSize(
            width: min(max(proposed.width, minX), maxX),
            height: min(max(proposed.height, minY), maxY)
        )
    }

    func showToast(_ message: String) {
        withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
            toast = message
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            withAnimation(.easeOut(duration: 0.18)) {
                if toast == message {
                    toast = nil
                }
            }
        }
    }
}

private func habitGardenKey(_ habit: HTHabit) -> String {
    String(describing: habit.persistentModelID)
        .replacingOccurrences(of: "/", with: "_")
        .replacingOccurrences(of: ":", with: "_")
        .replacingOccurrences(of: " ", with: "_")
}

private struct HabitGardenState: Codable, Equatable {
    var plants: [HabitGardenPlant] = []
    var water: Int = 8
    var sun: Int = 4
    var fertilizer: Int = 1
    var coins: Int = 20
    var lastRewardDay: Int = 0
}

private struct GardenCoordinate: Codable, Equatable, Hashable {
    let x: Int
    let y: Int
}

private struct HabitGardenPlant: Codable, Identifiable, Equatable {
    var id: String { "\(x):\(y)" }

    let x: Int
    let y: Int
    let plantedDay: Int
    var wateredDays: [Int]
    var sunPoints: Int
    var fertilizerPoints: Int

    var symbol: String {
        switch growthStage {
        case 0: return "•"
        case 1: return "⌁"
        case 2: return "♧"
        case 3: return "✿"
        default: return "✦"
        }
    }

    var assetName: String {
        switch growthStage {
        case 0: return "agabloom_seed"
        case 1: return "agabloom_sprout"
        case 2: return "agabloom_small"
        case 3: return "agabloom_medium"
        default: return "agabloom_bloom"
        }
    }

    var assetScale: CGSize {
        switch growthStage {
        case 0: return CGSize(width: 0.62, height: 0.62)
        case 1: return CGSize(width: 0.74, height: 0.74)
        case 2: return CGSize(width: 0.98, height: 0.86)
        case 3: return CGSize(width: 1.06, height: 0.92)
        default: return CGSize(width: 1.18, height: 0.98)
        }
    }

    var growthScore: Int {
        Set(wateredDays).count + sunPoints + fertilizerPoints * 2
    }

    var growthStage: Int {
        min(growthScore / 2, 4)
    }

    func isWateredToday(_ day: Int) -> Bool {
        wateredDays.contains(day)
    }

    func statusText(today: Int) -> String {
        if growthStage >= 4 {
            return "Floresceu. Continue cuidando para manter viva."
        }
        let remaining = max(8 - growthScore, 0)
        if isWateredToday(today) {
            return "Regada hoje. Faltam \(remaining) cuidados para florescer."
        }
        return "Precisa de cuidado. Faltam \(remaining) cuidados para florescer."
    }
}
