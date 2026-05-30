import SwiftUI
import SwiftData

struct FarmGardenView: View {
    let assetMode: Bool

    @Query(sort: \HTHabit.createdAt, order: .forward)
    private var habits: [HTHabit]

    @Query(sort: \HTHabitLog.date, order: .forward)
    private var allLogs: [HTHabitLog]

    @AppStorage("appearance.uiScale") private var uiScale: Double = 0.85
    @AppStorage("farm.plots") private var encodedPlots = ""
    @AppStorage("farm.habitPlots") private var encodedHabitPlots = ""
    @AppStorage("farm.coins") private var coins = 80
    @AppStorage("farm.water") private var water = 10
    @AppStorage("farm.fertilizer") private var fertilizer = 2
    @AppStorage("farm.harvests") private var harvests = 0
    @AppStorage("farm.lastDailyOrdinal") private var lastDailyOrdinal = 0

    @State private var plots: [FarmPlot] = FarmPlot.starterPlots
    @State private var plotsByGarden: [String: [FarmPlot]] = [:]
    @State private var selectedGardenIndex = 0
    @State private var selectedTool: FarmTool = .plant
    @State private var selectedCrop: CropKind = .leafling
    @State private var selectedPlotID: Int?
    @State private var toast: String?
    @State private var pulsePlotID: Int?

    private let accent = Color(red: 0.39, green: 0.88, blue: 0.28)
    private let assetGroundBleed: CGFloat = 1.03

    init(assetMode: Bool = false) {
        self.assetMode = assetMode
    }

    private var scale: CGFloat {
        CGFloat(min(max(uiScale, 0.75), 1.0))
    }

    private func scaled(_ value: CGFloat) -> CGFloat {
        value * scale
    }

    var body: some View {
        ZStack {
            background

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: scaled(16)) {
                    header
                    questCard
                    farmPager
                    selectedPlotCard
                }
                .padding(.horizontal, scaled(16))
                .padding(.top, scaled(18))
                .padding(.bottom, scaled(24))
            }
            .ignoresSafeArea(.container, edges: .bottom)

            if let toast {
                VStack {
                    Spacer()
                    Text(toast)
                        .font(.system(size: scaled(14), weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, scaled(16))
                        .padding(.vertical, scaled(10))
                        .background(Color.black.opacity(0.78))
                        .clipShape(Capsule())
                        .padding(.bottom, scaled(86))
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .preferredColorScheme(.dark)
        .onAppear {
            loadPlotStore()
            syncPlotsForSelectedGarden()
            claimDailyRewardsIfNeeded()
        }
        .onChange(of: plots) { _, _ in
            saveCurrentPlots()
        }
        .onChange(of: selectedGardenIndex) { _, _ in
            syncPlotsForSelectedGarden()
        }
        .onChange(of: habits.count) { _, _ in
            selectedGardenIndex = min(selectedGardenIndex, max(gardenPages.count - 1, 0))
            syncPlotsForSelectedGarden()
        }
    }

    private var background: some View {
        HTAppBackground()
    }

    private var header: some View {
        HStack(alignment: .top, spacing: scaled(14)) {
            VStack(alignment: .leading, spacing: scaled(6)) {
                Text(assetMode ? "Jardim de Assets" : "Jardim de Ícones")
                    .font(.system(size: scaled(32), weight: .bold))
                    .foregroundStyle(.white)

                Text("Arraste para o lado e cuide de um jardim por hábito.")
                    .font(.system(size: scaled(15), weight: .medium))
                    .foregroundStyle(.white.opacity(0.64))
                    .lineLimit(2)
            }

            Spacer()

            VStack(spacing: scaled(4)) {
                gardenIcon(asset: weatherAsset, systemIcon: weatherSymbol, color: weatherColor, size: 26)

                Text(seasonLabel)
                    .font(.system(size: scaled(10), weight: .bold))
                    .foregroundStyle(.white.opacity(0.64))
            }
            .frame(width: scaled(58), height: scaled(58))
            .background(Color.white.opacity(0.07))
            .clipShape(RoundedRectangle(cornerRadius: scaled(18), style: .continuous))
            .overlay(cardStroke(scaled(18)))
        }
    }

    private var resourceBar: some View {
        HStack(spacing: scaled(8)) {
            resourceChip(icon: "circle.hexagongrid.fill", asset: assetMode ? "fx_sparkle_2" : nil, value: "\(coins)", label: "Moedas", color: Color.yellow)
            resourceChip(icon: "drop.fill", asset: assetMode ? "item_water" : nil, value: "\(water)", label: "Água", color: Color(red: 0.24, green: 0.62, blue: 1.0))
            resourceChip(icon: "sparkles", asset: assetMode ? "item_fertilizer" : nil, value: "\(fertilizer)", label: "Adubo", color: Color(red: 0.70, green: 0.50, blue: 0.28))
            resourceChip(icon: "basket.fill", asset: assetMode ? "agabloom_bloom" : nil, value: "\(harvests)", label: "Colheitas", color: accent)
        }
    }

    private func resourceChip(icon: String, asset: String? = nil, value: String, label: String, color: Color) -> some View {
        HStack(spacing: scaled(7)) {
            gardenIcon(asset: asset, systemIcon: icon, color: color, size: 17)

            VStack(alignment: .leading, spacing: 0) {
                Text(value)
                    .font(.system(size: scaled(15), weight: .bold))
                    .foregroundStyle(.white)

                Text(label)
                    .font(.system(size: scaled(9), weight: .semibold))
                    .foregroundStyle(.white.opacity(0.50))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, scaled(10))
        .background(Color.white.opacity(0.065))
        .clipShape(RoundedRectangle(cornerRadius: scaled(16), style: .continuous))
        .overlay(cardStroke(scaled(16)))
    }

    private var questCard: some View {
        let completedToday = todayLogsCount
        let target = max(3, min(8, allLogs.count / 8 + 3))
        let progress = min(CGFloat(completedToday) / CGFloat(target), 1)

        return VStack(alignment: .leading, spacing: scaled(10)) {
            HStack {
                Label("Pedido do dia", systemImage: "list.bullet.clipboard.fill")
                    .font(.system(size: scaled(16), weight: .bold))
                    .foregroundStyle(.white)

                Spacer()

                Text("\(completedToday)/\(target)")
                    .font(.system(size: scaled(14), weight: .bold))
                    .foregroundStyle(accent)
            }

            Text("Conclua hábitos hoje para receber água, moedas e acelerar a fazenda amanhã.")
                .font(.system(size: scaled(13), weight: .medium))
                .foregroundStyle(.white.opacity(0.62))
                .lineLimit(2)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.10))

                    Capsule()
                        .fill(accent)
                        .frame(width: geo.size.width * progress)
                }
            }
            .frame(height: scaled(7))
        }
        .padding(scaled(15))
        .background(
            LinearGradient(
                colors: [Color.white.opacity(0.075), Color.green.opacity(0.06)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: scaled(20), style: .continuous))
        .overlay(cardStroke(scaled(20)))
    }

    private var cropPicker: some View {
        VStack(alignment: .leading, spacing: scaled(10)) {
            Text("Sementes")
                .font(.system(size: scaled(16), weight: .bold))
                .foregroundStyle(.white)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: scaled(10)) {
                    ForEach(CropKind.allCases) { crop in
                        Button {
                            selectedCrop = crop
                            selectedTool = .plant
                        } label: {
                            VStack(spacing: scaled(6)) {
                                gardenIcon(asset: assetMode ? crop.seedAssetName : nil, systemIcon: crop.symbol, color: crop.color, size: 25)

                                Text(crop.title)
                                    .font(.system(size: scaled(11), weight: .bold))
                                    .foregroundStyle(.white)

                                Text("\(crop.seedCost) moedas")
                                    .font(.system(size: scaled(9), weight: .semibold))
                                    .foregroundStyle(.white.opacity(0.54))
                            }
                            .frame(width: scaled(86), height: scaled(82))
                            .background(selectedCrop == crop ? crop.color.opacity(0.22) : Color.white.opacity(0.055))
                            .clipShape(RoundedRectangle(cornerRadius: scaled(18), style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: scaled(18), style: .continuous)
                                    .strokeBorder(selectedCrop == crop ? crop.color.opacity(0.70) : Color.white.opacity(0.08), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var farmPager: some View {
        GeometryReader { geo in
            let pagerHeight = farmPagerHeight(for: geo.size.width)

            TabView(selection: $selectedGardenIndex) {
                ForEach(gardenPages.indices, id: \.self) { index in
                    farmBoard(for: gardenPages[index])
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: gardenPages.count > 1 ? .automatic : .never))
            .frame(width: geo.size.width, height: pagerHeight)
        }
        .frame(height: farmPagerHeight(for: UIScreen.main.bounds.width - scaled(32)))
    }

    private func farmBoard(for page: FarmGardenPage) -> some View {
        VStack(alignment: .leading, spacing: scaled(12)) {
            HStack {
                VStack(alignment: .leading, spacing: scaled(2)) {
                    Text(page.title)
                        .font(.system(size: scaled(18), weight: .bold))
                        .foregroundStyle(.white)

                    Text(page.subtitle)
                        .font(.system(size: scaled(11), weight: .semibold))
                        .foregroundStyle(.white.opacity(0.52))
                        .lineLimit(1)
                }

                Spacer()

                Text(selectedTool.title)
                    .font(.system(size: scaled(12), weight: .bold))
                    .foregroundStyle(selectedTool.color)
                    .padding(.horizontal, scaled(10))
                    .padding(.vertical, scaled(6))
                    .background(selectedTool.color.opacity(0.16))
                    .clipShape(Capsule())
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: assetMode ? 0 : scaled(8)), count: 4), spacing: assetMode ? 0 : scaled(8)) {
                ForEach(plots) { plot in
                    Button {
                        handleTap(plot)
                    } label: {
                        plotTile(plot)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(scaled(14))
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.06, green: 0.12, blue: 0.08),
                    Color.white.opacity(0.045)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: scaled(24), style: .continuous))
        .overlay(cardStroke(scaled(24)))
    }

    private func plotTile(_ plot: FarmPlot) -> some View {
        let isSelected = selectedPlotID == plot.id
        let isPulsing = pulsePlotID == plot.id

        return ZStack {
            plotTileBackground(plot)

            VStack(spacing: scaled(4)) {
                cropVisual(plot)

                if plot.isWatered(on: todayOrdinal) {
                    gardenIcon(asset: assetMode ? "item_water" : nil, systemIcon: "drop.fill", color: Color(red: 0.38, green: 0.72, blue: 1.0), size: 12)
                }
            }
            .scaleEffect(isPulsing ? 1.12 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.55), value: isPulsing)
        }
        .aspectRatio(1, contentMode: .fit)
    }

    @ViewBuilder
    private func plotTileBackground(_ plot: FarmPlot) -> some View {
        let isSelected = selectedPlotID == plot.id
        let tileRadius = assetMode ? CGFloat(0) : scaled(13)

        RoundedRectangle(cornerRadius: tileRadius, style: .continuous)
            .fill(plot.soilColor(currentDay: todayOrdinal))
            .overlay {
                if assetMode {
                    Image(plot.groundAssetName)
                        .resizable()
                        .interpolation(.none)
                        .scaledToFill()
                        .scaleEffect(assetGroundBleed)
                        .clipShape(RoundedRectangle(cornerRadius: tileRadius, style: .continuous))
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: tileRadius, style: .continuous)
                    .strokeBorder(
                        isSelected ? accent.opacity(0.95) : (assetMode ? Color.clear : Color.black.opacity(0.22)),
                        lineWidth: isSelected ? 2 : (assetMode ? 0 : 1)
                    )
            )
    }

    @ViewBuilder
    private func cropVisual(_ plot: FarmPlot) -> some View {
        if let crop = plot.crop {
            let stage = plot.stage(currentDay: todayOrdinal)

            ZStack {
                if assetMode {
                    Image(plot.assetName(currentDay: todayOrdinal))
                        .resizable()
                        .interpolation(.high)
                        .scaledToFit()
                        .frame(width: scaled(assetCropSize(for: stage)), height: scaled(assetCropSize(for: stage)))
                        .offset(y: scaled(assetCropYOffset(for: stage)))
                } else if stage >= 2 {
                    gardenIcon(asset: nil, systemIcon: crop.symbol, color: crop.color, size: stage == 3 ? 27 : 22)
                } else if stage == 1 {
                    gardenIcon(asset: nil, systemIcon: "leaf.fill", color: crop.color.opacity(0.9), size: 20)
                } else {
                    Circle()
                        .fill(crop.color.opacity(0.75))
                        .frame(width: scaled(10), height: scaled(10))
                }

                if plot.isReady(currentDay: todayOrdinal) {
                    Circle()
                        .stroke(crop.color.opacity(0.40), lineWidth: 2)
                        .frame(width: scaled(42), height: scaled(42))
                }
            }
        } else {
            if assetMode == false {
                gardenIcon(asset: nil, systemIcon: "plus", color: .white.opacity(0.18), size: 22)
            }
        }
    }

    private var selectedPlotCard: some View {
        let plot = selectedPlot

        return VStack(alignment: .leading, spacing: scaled(10)) {
            HStack {
                Text(plot?.title(currentDay: todayOrdinal) ?? "Selecione um canteiro")
                    .font(.system(size: scaled(17), weight: .bold))
                    .foregroundStyle(.white)

                Spacer()

                if let plot, plot.isReady(currentDay: todayOrdinal) {
                    Text("Pronto")
                        .font(.system(size: scaled(12), weight: .bold))
                        .foregroundStyle(accent)
                }
            }

            Text(plot?.detail(currentDay: todayOrdinal) ?? "Escolha uma ferramenta e toque em um canteiro para plantar, regar ou colher.")
                .font(.system(size: scaled(13), weight: .medium))
                .foregroundStyle(.white.opacity(0.62))
                .lineLimit(3)

            HStack(spacing: scaled(10)) {
                quickAction("Plantar", icon: "leaf.fill", asset: assetMode ? "agabloom_seed" : nil, tool: .plant)
                quickAction("Regar", icon: "drop.fill", asset: assetMode ? "item_water" : nil, tool: .water)
                quickAction("Adubar", icon: "sparkles", asset: assetMode ? "item_fertilizer" : nil, tool: .fertilize)
                quickAction("Colher", icon: "basket.fill", asset: assetMode ? "agabloom_bloom" : nil, tool: .harvest)
                quickAction("Remover", icon: "trash.fill", asset: nil, tool: .remove)
            }
        }
        .padding(scaled(15))
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: scaled(20), style: .continuous))
        .overlay(cardStroke(scaled(20)))
    }

    private func quickAction(_ title: String, icon: String, asset: String? = nil, tool: FarmTool) -> some View {
        Button {
            selectedTool = tool
            if let plot = selectedPlot {
                handleTap(plot)
            }
        } label: {
            HStack(spacing: scaled(5)) {
                gardenIcon(asset: asset, systemIcon: icon, color: selectedTool == tool ? tool.color : .white.opacity(0.66), size: 15)
                Text(title)
            }
                .font(.system(size: scaled(12), weight: .bold))
                .foregroundStyle(selectedTool == tool ? tool.color : .white.opacity(0.66))
                .frame(maxWidth: .infinity)
                .padding(.vertical, scaled(9))
                .background(selectedTool == tool ? tool.color.opacity(0.16) : Color.white.opacity(0.06))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private func assetCropSize(for stage: Int) -> CGFloat {
        switch stage {
        case 0: return 30
        case 1: return 38
        case 2: return 48
        default: return 58
        }
    }

    private func assetCropYOffset(for stage: Int) -> CGFloat {
        switch stage {
        case 0: return 4
        case 1: return 2
        case 2: return 0
        default: return -2
        }
    }

    private func farmPagerHeight(for availableWidth: CGFloat) -> CGFloat {
        if assetMode == false {
            return scaled(356)
        }

        let boardPadding = scaled(14) * 2
        let headerHeight = scaled(43)
        let gridWidth = max(0, availableWidth - boardPadding)
        let pageControlRoom = gardenPages.count > 1 ? scaled(22) : 0
        return boardPadding + headerHeight + scaled(12) + gridWidth + pageControlRoom
    }

    private func cardStroke(_ radius: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: radius, style: .continuous)
            .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
    }

    @ViewBuilder
    private func gardenIcon(asset: String?, systemIcon: String, color: Color, size: CGFloat) -> some View {
        if assetMode, let asset {
            Image(asset)
                .resizable()
                .interpolation(.none)
                .scaledToFit()
                .frame(width: scaled(size), height: scaled(size))
        } else {
            Image(systemName: systemIcon)
                .font(.system(size: scaled(size), weight: .bold))
                .foregroundStyle(color)
        }
    }
}

// MARK: - Actions

private extension FarmGardenView {
    var selectedPlot: FarmPlot? {
        plots.first(where: { $0.id == selectedPlotID })
    }

    func handleTap(_ plot: FarmPlot) {
        selectedPlotID = plot.id

        guard let index = plots.firstIndex(where: { $0.id == plot.id }) else { return }

        switch selectedTool {
        case .inspect:
            showToast(plots[index].detail(currentDay: todayOrdinal))

        case .plant:
            guard plots[index].crop == nil else {
                showToast("Esse canteiro já está ocupado.")
                return
            }
            guard coins >= selectedCrop.seedCost else {
                showToast("Moedas insuficientes para essa semente.")
                return
            }
            coins -= selectedCrop.seedCost
            plots[index].crop = selectedCrop
            plots[index].plantedDay = todayOrdinal
            plots[index].wateredDays = []
            plots[index].quality = 0
            pulse(plotID: plot.id)
            showToast("\(selectedCrop.title) plantado.")

        case .water:
            guard plots[index].crop != nil else {
                showToast("Plante algo antes de regar.")
                return
            }
            guard !plots[index].isWatered(on: todayOrdinal) else {
                showToast("Esse canteiro já foi regado hoje.")
                return
            }
            guard water > 0 else {
                showToast("Você está sem água. Conclua hábitos para ganhar mais.")
                return
            }
            water -= 1
            plots[index].wateredDays.append(todayOrdinal)
            plots[index].quality += todayLogsCount > 0 ? 1 : 0
            pulse(plotID: plot.id)
            showToast("Canteiro regado.")

        case .fertilize:
            guard plots[index].crop != nil else {
                showToast("Plante algo antes de adubar.")
                return
            }
            guard fertilizer > 0 else {
                showToast("Você está sem adubo.")
                return
            }
            fertilizer -= 1
            plots[index].quality += 2
            pulse(plotID: plot.id)
            showToast("Adubo aplicado.")

        case .harvest:
            guard plots[index].isReady(currentDay: todayOrdinal), let crop = plots[index].crop else {
                showToast("Ainda não está pronto para colher.")
                return
            }
            let reward = crop.sellValue + plots[index].quality * 2
            coins += reward
            harvests += 1
            plots[index] = FarmPlot.empty(id: plot.id)
            pulse(plotID: plot.id)
            showToast("Colheita vendida por \(reward) moedas.")

        case .remove:
            guard plots[index].crop != nil else {
                showToast("Esse canteiro já está vazio.")
                return
            }
            plots[index] = FarmPlot.empty(id: plot.id)
            pulse(plotID: plot.id)
            showToast("Planta removida.")
        }
    }

    func showToast(_ message: String) {
        withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
            toast = message
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.1) {
            withAnimation(.easeOut(duration: 0.18)) {
                if toast == message {
                    toast = nil
                }
            }
        }
    }

    func pulse(plotID: Int) {
        pulsePlotID = plotID
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.24) {
            if pulsePlotID == plotID {
                pulsePlotID = nil
            }
        }
    }
}

// MARK: - Persistence and Derived Values

private extension FarmGardenView {
    var gardenPages: [FarmGardenPage] {
        if habits.isEmpty {
            return [
                FarmGardenPage(
                    id: "garden-general",
                    title: "Jardim geral",
                    subtitle: "Crie hábitos para separar os canteiros"
                )
            ]
        }

        return habits.map { habit in
            FarmGardenPage(
                id: habitGardenKey(habit),
                title: habit.name,
                subtitle: habit.detailText.isEmpty ? "Jardim do hábito" : habit.detailText
            )
        }
    }

    var currentGardenPage: FarmGardenPage {
        gardenPages[min(selectedGardenIndex, max(gardenPages.count - 1, 0))]
    }

    var todayOrdinal: Int {
        Calendar.current.ordinality(of: .day, in: .era, for: .now) ?? 0
    }

    var todayLogsCount: Int {
        let cal = Calendar.current
        return allLogs.filter { cal.isDateInToday($0.date) }.count
    }

    var seasonLabel: String {
        let day = todayOrdinal % 28
        switch day {
        case 0..<7: return "Primavera"
        case 7..<14: return "Verão"
        case 14..<21: return "Outono"
        default: return "Inverno"
        }
    }

    var weatherSymbol: String {
        todayLogsCount >= 4 ? "sun.max.fill" : (todayLogsCount > 0 ? "cloud.sun.fill" : "cloud.drizzle.fill")
    }

    var weatherColor: Color {
        todayLogsCount >= 4 ? .yellow : (todayLogsCount > 0 ? accent : Color(red: 0.35, green: 0.65, blue: 1.0))
    }

    var weatherAsset: String {
        todayLogsCount >= 4 ? "item_sun" : (todayLogsCount > 0 ? "fx_sparkle_1" : "item_water")
    }

    func claimDailyRewardsIfNeeded() {
        guard lastDailyOrdinal != todayOrdinal else { return }

        let completions = todayLogsCount
        water += 6 + completions
        coins += completions * 4
        fertilizer += min(completions / 3, 2)
        lastDailyOrdinal = todayOrdinal
    }

    func loadPlotStore() {
        if encodedHabitPlots.isEmpty == false,
           let data = encodedHabitPlots.data(using: .utf8),
           let decoded = try? JSONDecoder().decode([String: [FarmPlot]].self, from: data) {
            plotsByGarden = decoded
            return
        }

        if encodedPlots.isEmpty == false,
           let data = encodedPlots.data(using: .utf8),
           let decoded = try? JSONDecoder().decode([FarmPlot].self, from: data),
           decoded.count == FarmPlot.starterPlots.count {
            plotsByGarden[currentGardenPage.id] = decoded
            savePlotStore()
            return
        }
    }

    func syncPlotsForSelectedGarden() {
        selectedPlotID = nil
        plots = plotsByGarden[currentGardenPage.id] ?? FarmPlot.starterPlots
    }

    func saveCurrentPlots() {
        plotsByGarden[currentGardenPage.id] = plots
        savePlotStore()

        guard let data = try? JSONEncoder().encode(plots),
              let string = String(data: data, encoding: .utf8) else { return }
        encodedPlots = string
    }

    func savePlotStore() {
        guard let data = try? JSONEncoder().encode(plotsByGarden),
              let string = String(data: data, encoding: .utf8) else { return }
        encodedHabitPlots = string
    }

    func habitGardenKey(_ habit: HTHabit) -> String {
        let createdAt = Int(habit.createdAt.timeIntervalSinceReferenceDate)
        return "habit-\(createdAt)-\(habit.name)"
    }
}

private enum FarmTool: String, CaseIterable, Identifiable {
    case inspect
    case plant
    case water
    case fertilize
    case harvest
    case remove

    var id: String { rawValue }

    var title: String {
        switch self {
        case .inspect: return "Olhar"
        case .plant: return "Plantar"
        case .water: return "Regar"
        case .fertilize: return "Adubar"
        case .harvest: return "Colher"
        case .remove: return "Remover"
        }
    }

    var symbol: String {
        switch self {
        case .inspect: return "magnifyingglass"
        case .plant: return "leaf.fill"
        case .water: return "drop.fill"
        case .fertilize: return "sparkles"
        case .harvest: return "basket.fill"
        case .remove: return "trash.fill"
        }
    }

    var color: Color {
        switch self {
        case .inspect: return .white.opacity(0.80)
        case .plant: return Color(red: 0.39, green: 0.88, blue: 0.28)
        case .water: return Color(red: 0.28, green: 0.62, blue: 1.0)
        case .fertilize: return Color(red: 0.78, green: 0.54, blue: 0.26)
        case .harvest: return Color.yellow
        case .remove: return Color(red: 1.0, green: 0.36, blue: 0.32)
        }
    }

    var assetName: String {
        switch self {
        case .inspect: return "fx_sparkle_1"
        case .plant: return "agabloom_seed"
        case .water: return "item_water"
        case .fertilize: return "item_fertilizer"
        case .harvest: return "agabloom_bloom"
        case .remove: return "fx_sparkle_1"
        }
    }
}

private struct FarmGardenPage: Identifiable, Equatable {
    let id: String
    let title: String
    let subtitle: String
}

private enum CropKind: String, Codable, CaseIterable, Identifiable {
    case leafling
    case berry
    case sunroot
    case moonMint

    var id: String { rawValue }

    var title: String {
        switch self {
        case .leafling: return "Folhinha"
        case .berry: return "Frutinha"
        case .sunroot: return "Raiz Solar"
        case .moonMint: return "Hortelã"
        }
    }

    var symbol: String {
        switch self {
        case .leafling: return "leaf.fill"
        case .berry: return "circle.grid.cross.fill"
        case .sunroot: return "sun.max.fill"
        case .moonMint: return "moon.stars.fill"
        }
    }

    var color: Color {
        switch self {
        case .leafling: return Color(red: 0.39, green: 0.88, blue: 0.28)
        case .berry: return Color(red: 0.92, green: 0.28, blue: 0.46)
        case .sunroot: return Color.yellow
        case .moonMint: return Color(red: 0.58, green: 0.44, blue: 1.0)
        }
    }

    var daysToMature: Int {
        switch self {
        case .leafling: return 2
        case .berry: return 3
        case .sunroot: return 4
        case .moonMint: return 3
        }
    }

    var seedCost: Int {
        switch self {
        case .leafling: return 8
        case .berry: return 12
        case .sunroot: return 18
        case .moonMint: return 15
        }
    }

    var sellValue: Int {
        switch self {
        case .leafling: return 16
        case .berry: return 28
        case .sunroot: return 42
        case .moonMint: return 34
        }
    }

    var seedAssetName: String {
        switch self {
        case .leafling: return "agabloom_seed"
        case .berry: return "agabloom_sprout"
        case .sunroot: return "agabloom_small"
        case .moonMint: return "agabloom_medium"
        }
    }
}

private struct FarmPlot: Codable, Identifiable, Equatable {
    let id: Int
    var crop: CropKind?
    var plantedDay: Int?
    var wateredDays: [Int]
    var quality: Int

    static var starterPlots: [FarmPlot] {
        (0..<16).map { FarmPlot.empty(id: $0) }
    }

    static func empty(id: Int) -> FarmPlot {
        FarmPlot(id: id, crop: nil, plantedDay: nil, wateredDays: [], quality: 0)
    }

    func isWatered(on day: Int) -> Bool {
        wateredDays.contains(day)
    }

    func stage(currentDay: Int) -> Int {
        guard let crop else { return 0 }
        let watered = Set(wateredDays).count
        if watered >= crop.daysToMature { return 3 }
        if watered >= max(1, crop.daysToMature / 2) { return 2 }
        if watered > 0 { return 1 }
        return 0
    }

    func isReady(currentDay: Int) -> Bool {
        guard let crop else { return false }
        return Set(wateredDays).count >= crop.daysToMature
    }

    func assetName(currentDay: Int) -> String {
        switch stage(currentDay: currentDay) {
        case 0: return "agabloom_seed"
        case 1: return "agabloom_sprout"
        case 2: return "agabloom_small"
        default: return "agabloom_bloom"
        }
    }

    var groundAssetName: String {
        if crop != nil {
            return "soil_64"
        }

        let row = id / 4
        let column = id % 4
        return (row + column).isMultiple(of: 2) ? "grass_light_64" : "grass_dark_64"
    }

    func soilColor(currentDay: Int) -> Color {
        if crop == nil {
            return Color(red: 0.22, green: 0.13, blue: 0.07).opacity(0.88)
        }

        if isWatered(on: currentDay) {
            return Color(red: 0.17, green: 0.12, blue: 0.08).opacity(0.96)
        }

        return Color(red: 0.28, green: 0.17, blue: 0.09).opacity(0.96)
    }

    func title(currentDay: Int) -> String {
        guard let crop else { return "Canteiro vazio" }
        if isReady(currentDay: currentDay) { return "\(crop.title) pronta" }
        return crop.title
    }

    func detail(currentDay: Int) -> String {
        guard let crop else {
            return "Terra pronta para receber uma nova semente."
        }

        let watered = Set(wateredDays).count
        let remaining = max(crop.daysToMature - watered, 0)
        let waterText = isWatered(on: currentDay) ? "Regado hoje." : "Ainda precisa de água hoje."

        if remaining == 0 {
            return "Pronto para colher. Valor base: \(crop.sellValue) moedas."
        }

        return "\(waterText) Faltam \(remaining) regas para amadurecer."
    }
}
