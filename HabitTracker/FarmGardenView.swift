import SwiftUI
import SwiftData

struct FarmGardenView: View {
    @Query(sort: \HTHabitLog.date, order: .forward)
    private var allLogs: [HTHabitLog]

    @AppStorage("appearance.uiScale") private var uiScale: Double = 0.85
    @AppStorage("farm.plots") private var encodedPlots = ""
    @AppStorage("farm.coins") private var coins = 80
    @AppStorage("farm.water") private var water = 10
    @AppStorage("farm.fertilizer") private var fertilizer = 2
    @AppStorage("farm.harvests") private var harvests = 0
    @AppStorage("farm.lastDailyOrdinal") private var lastDailyOrdinal = 0

    @State private var plots: [FarmPlot] = FarmPlot.starterPlots
    @State private var selectedTool: FarmTool = .plant
    @State private var selectedCrop: CropKind = .leafling
    @State private var selectedPlotID: Int?
    @State private var toast: String?
    @State private var pulsePlotID: Int?

    private let accent = Color(red: 0.39, green: 0.88, blue: 0.28)

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
                    resourceBar
                    questCard
                    cropPicker
                    farmBoard
                    toolBelt
                    selectedPlotCard
                }
                .padding(.horizontal, scaled(16))
                .padding(.top, scaled(18))
                .padding(.bottom, scaled(112))
            }

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
            loadPlots()
            claimDailyRewardsIfNeeded()
        }
        .onChange(of: plots) { _, _ in
            savePlots()
        }
    }

    private var background: some View {
        ZStack {
            Color(red: 0.01, green: 0.035, blue: 0.03)
                .ignoresSafeArea()

            LinearGradient(
                colors: [
                    Color.green.opacity(0.12),
                    Color.clear,
                    Color(red: 0.10, green: 0.06, blue: 0.02).opacity(0.22)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: scaled(14)) {
            VStack(alignment: .leading, spacing: scaled(6)) {
                Text("Jardim de Ícones")
                    .font(.system(size: scaled(32), weight: .bold))
                    .foregroundStyle(.white)

                Text("Plante, regue e colha usando a energia dos seus hábitos.")
                    .font(.system(size: scaled(15), weight: .medium))
                    .foregroundStyle(.white.opacity(0.64))
                    .lineLimit(2)
            }

            Spacer()

            VStack(spacing: scaled(4)) {
                Image(systemName: weatherSymbol)
                    .font(.system(size: scaled(24), weight: .bold))
                    .foregroundStyle(weatherColor)

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
            resourceChip(icon: "circle.hexagongrid.fill", value: "\(coins)", label: "Moedas", color: Color.yellow)
            resourceChip(icon: "drop.fill", value: "\(water)", label: "Água", color: Color(red: 0.24, green: 0.62, blue: 1.0))
            resourceChip(icon: "sparkles", value: "\(fertilizer)", label: "Adubo", color: Color(red: 0.70, green: 0.50, blue: 0.28))
            resourceChip(icon: "basket.fill", value: "\(harvests)", label: "Colheitas", color: accent)
        }
    }

    private func resourceChip(icon: String, value: String, label: String, color: Color) -> some View {
        HStack(spacing: scaled(7)) {
            Image(systemName: icon)
                .font(.system(size: scaled(15), weight: .bold))
                .foregroundStyle(color)

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
                                Image(systemName: crop.symbol)
                                    .font(.system(size: scaled(22), weight: .bold))
                                    .foregroundStyle(crop.color)

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

    private var farmBoard: some View {
        VStack(alignment: .leading, spacing: scaled(12)) {
            HStack {
                Text("Canteiros")
                    .font(.system(size: scaled(18), weight: .bold))
                    .foregroundStyle(.white)

                Spacer()

                Text(selectedTool.title)
                    .font(.system(size: scaled(12), weight: .bold))
                    .foregroundStyle(selectedTool.color)
                    .padding(.horizontal, scaled(10))
                    .padding(.vertical, scaled(6))
                    .background(selectedTool.color.opacity(0.16))
                    .clipShape(Capsule())
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: scaled(8)), count: 4), spacing: scaled(8)) {
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
            RoundedRectangle(cornerRadius: scaled(13), style: .continuous)
                .fill(plot.soilColor(currentDay: todayOrdinal))
                .overlay(
                    RoundedRectangle(cornerRadius: scaled(13), style: .continuous)
                        .strokeBorder(isSelected ? accent.opacity(0.95) : Color.black.opacity(0.22), lineWidth: isSelected ? 2 : 1)
                )

            VStack(spacing: scaled(4)) {
                cropVisual(plot)

                if plot.isWatered(on: todayOrdinal) {
                    Image(systemName: "drop.fill")
                        .font(.system(size: scaled(9), weight: .bold))
                        .foregroundStyle(Color(red: 0.38, green: 0.72, blue: 1.0))
                }
            }
            .scaleEffect(isPulsing ? 1.12 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.55), value: isPulsing)
        }
        .aspectRatio(1, contentMode: .fit)
    }

    @ViewBuilder
    private func cropVisual(_ plot: FarmPlot) -> some View {
        if let crop = plot.crop {
            let stage = plot.stage(currentDay: todayOrdinal)

            ZStack {
                if stage >= 2 {
                    Image(systemName: crop.symbol)
                        .font(.system(size: scaled(stage == 3 ? 27 : 22), weight: .bold))
                        .foregroundStyle(crop.color)
                } else if stage == 1 {
                    Image(systemName: "leaf.fill")
                        .font(.system(size: scaled(20), weight: .bold))
                        .foregroundStyle(crop.color.opacity(0.9))
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
            Image(systemName: "plus")
                .font(.system(size: scaled(18), weight: .bold))
                .foregroundStyle(.white.opacity(0.18))
        }
    }

    private var toolBelt: some View {
        HStack(spacing: scaled(8)) {
            ForEach(FarmTool.allCases) { tool in
                Button {
                    selectedTool = tool
                } label: {
                    VStack(spacing: scaled(5)) {
                        Image(systemName: tool.symbol)
                            .font(.system(size: scaled(19), weight: .bold))

                        Text(tool.title)
                            .font(.system(size: scaled(9), weight: .bold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    .foregroundStyle(selectedTool == tool ? tool.color : .white.opacity(0.55))
                    .frame(maxWidth: .infinity)
                    .frame(height: scaled(58))
                    .background(selectedTool == tool ? tool.color.opacity(0.18) : Color.white.opacity(0.055))
                    .clipShape(RoundedRectangle(cornerRadius: scaled(17), style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: scaled(17), style: .continuous)
                            .strokeBorder(selectedTool == tool ? tool.color.opacity(0.70) : Color.white.opacity(0.08), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
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
                quickAction("Plantar", icon: "leaf.fill", tool: .plant)
                quickAction("Regar", icon: "drop.fill", tool: .water)
                quickAction("Colher", icon: "basket.fill", tool: .harvest)
            }
        }
        .padding(scaled(15))
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: scaled(20), style: .continuous))
        .overlay(cardStroke(scaled(20)))
    }

    private func quickAction(_ title: String, icon: String, tool: FarmTool) -> some View {
        Button {
            selectedTool = tool
            if let plot = selectedPlot {
                handleTap(plot)
            }
        } label: {
            Label(title, systemImage: icon)
                .font(.system(size: scaled(12), weight: .bold))
                .foregroundStyle(selectedTool == tool ? tool.color : .white.opacity(0.66))
                .frame(maxWidth: .infinity)
                .padding(.vertical, scaled(9))
                .background(selectedTool == tool ? tool.color.opacity(0.16) : Color.white.opacity(0.06))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private func cardStroke(_ radius: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: radius, style: .continuous)
            .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
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

    func claimDailyRewardsIfNeeded() {
        guard lastDailyOrdinal != todayOrdinal else { return }

        let completions = todayLogsCount
        water += 6 + completions
        coins += completions * 4
        fertilizer += min(completions / 3, 2)
        lastDailyOrdinal = todayOrdinal
    }

    func loadPlots() {
        guard
            encodedPlots.isEmpty == false,
            let data = encodedPlots.data(using: .utf8),
            let decoded = try? JSONDecoder().decode([FarmPlot].self, from: data),
            decoded.count == FarmPlot.starterPlots.count
        else {
            plots = FarmPlot.starterPlots
            savePlots()
            return
        }

        plots = decoded
    }

    func savePlots() {
        guard let data = try? JSONEncoder().encode(plots),
              let string = String(data: data, encoding: .utf8) else { return }
        encodedPlots = string
    }
}

private enum FarmTool: String, CaseIterable, Identifiable {
    case inspect
    case plant
    case water
    case fertilize
    case harvest

    var id: String { rawValue }

    var title: String {
        switch self {
        case .inspect: return "Olhar"
        case .plant: return "Plantar"
        case .water: return "Regar"
        case .fertilize: return "Adubar"
        case .harvest: return "Colher"
        }
    }

    var symbol: String {
        switch self {
        case .inspect: return "magnifyingglass"
        case .plant: return "leaf.fill"
        case .water: return "drop.fill"
        case .fertilize: return "sparkles"
        case .harvest: return "basket.fill"
        }
    }

    var color: Color {
        switch self {
        case .inspect: return .white.opacity(0.80)
        case .plant: return Color(red: 0.39, green: 0.88, blue: 0.28)
        case .water: return Color(red: 0.28, green: 0.62, blue: 1.0)
        case .fertilize: return Color(red: 0.78, green: 0.54, blue: 0.26)
        case .harvest: return Color.yellow
        }
    }
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
