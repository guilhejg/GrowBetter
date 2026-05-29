import SwiftUI
import SwiftData

struct VisualGardenView: View {
    @Query(sort: \HTHabitLog.date, order: .forward)
    private var allLogs: [HTHabitLog]

    @AppStorage("appearance.uiScale") private var uiScale: Double = 0.85
    @AppStorage("visualGarden.plots") private var encodedPlots = ""
    @AppStorage("visualGarden.water") private var water = 8
    @AppStorage("visualGarden.sun") private var sun = 4
    @AppStorage("visualGarden.fertilizer") private var fertilizer = 2
    @AppStorage("visualGarden.harvests") private var harvests = 0
    @AppStorage("visualGarden.lastRewardDay") private var lastRewardDay = 0

    @State private var plots: [VisualGardenPlot] = VisualGardenPlot.defaultPlots
    @State private var selectedAction: VisualGardenAction = .plant
    @State private var selectedPlotID: Int?
    @State private var toast: String?
    @State private var sparklePlotID: Int?

    private let accent = Color(red: 0.39, green: 0.88, blue: 0.28)

    private var scale: CGFloat {
        CGFloat(min(max(uiScale, 0.75), 1.0))
    }

    private func scaled(_ value: CGFloat) -> CGFloat {
        value * scale
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            Image("bg_golden_brown")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
                .overlay(Color.black.opacity(0.20).ignoresSafeArea())

            LinearGradient(
                colors: [
                    Color.black.opacity(0.52),
                    Color.clear,
                    Color.black.opacity(0.45)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            GeometryReader { geo in
                let sceneHeight = gardenSceneHeight(for: geo.size)
                let sceneSize = CGSize(width: max(1, geo.size.width - scaled(32)), height: sceneHeight)
                let bottomInset = max(geo.safeAreaInsets.bottom + scaled(18), scaled(96))

                ZStack {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: scaled(14)) {
                            header
                            gardenScene(size: sceneSize)
                                .frame(width: sceneSize.width, height: sceneSize.height)
                            actionDock
                        }
                        .padding(.horizontal, scaled(16))
                        .padding(.top, max(geo.safeAreaInsets.top + scaled(12), scaled(18)))
                        .padding(.bottom, bottomInset)
                        .frame(maxWidth: .infinity, minHeight: geo.size.height, alignment: .top)
                    }

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
                                .padding(.bottom, bottomInset + scaled(12))
                        }
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .preferredColorScheme(.dark)
        .onAppear {
            loadPlots()
            claimDailyRewardIfNeeded()
        }
        .onChange(of: plots) { _, _ in
            savePlots()
        }
    }

    private func gardenSceneHeight(for size: CGSize) -> CGFloat {
        min(max(size.height * 0.42, scaled(300)), scaled(390))
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: scaled(12)) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: scaled(5)) {
                    Text("Jardim Vivo")
                        .font(.system(size: scaled(31), weight: .bold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)

                    Text("Toque nos canteiros para plantar, regar e colher.")
                        .font(.system(size: scaled(14), weight: .medium))
                        .foregroundStyle(.white.opacity(0.68))
                        .lineLimit(2)
                        .minimumScaleFactor(0.82)
                }
                .layoutPriority(1)

                Spacer()

                VStack(spacing: scaled(4)) {
                    Text("Nível \(gardenLevel)")
                        .font(.system(size: scaled(13), weight: .bold))
                        .foregroundStyle(accent)
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)

                    Text("\(harvests) colheitas")
                        .font(.system(size: scaled(10), weight: .semibold))
                        .foregroundStyle(.white.opacity(0.58))
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                }
                .padding(.horizontal, scaled(12))
                .padding(.vertical, scaled(9))
                .background(Color.black.opacity(0.38))
                .clipShape(RoundedRectangle(cornerRadius: scaled(16), style: .continuous))
                .overlay(cardStroke(scaled(16)))
            }

            HStack(spacing: scaled(8)) {
                resourcePill(image: "item_water", value: water, label: "Água")
                resourcePill(image: "item_sun", value: sun, label: "Luz")
                resourcePill(image: "item_fertilizer", value: fertilizer, label: "Adubo")
            }
        }
    }

    private func resourcePill(image: String, value: Int, label: String) -> some View {
        HStack(spacing: scaled(7)) {
            Image(image)
                .resizable()
                .scaledToFit()
                .frame(width: scaled(24), height: scaled(24))

            VStack(alignment: .leading, spacing: 0) {
                Text("\(value)")
                    .font(.system(size: scaled(14), weight: .bold))
                    .foregroundStyle(.white)

                Text(label)
                    .font(.system(size: scaled(9), weight: .semibold))
                    .foregroundStyle(.white.opacity(0.56))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, scaled(9))
        .background(Color.black.opacity(0.38))
        .clipShape(RoundedRectangle(cornerRadius: scaled(15), style: .continuous))
        .overlay(cardStroke(scaled(15)))
    }

    private func gardenScene(size: CGSize) -> some View {
        ZStack {
            ForEach(VisualGardenPlotPosition.all) { position in
                if let plot = plots.first(where: { $0.id == position.id }) {
                    plotButton(plot: plot, position: position, size: size)
                }
            }
        }
        .frame(width: size.width, height: size.height)
    }

    private func plotButton(plot: VisualGardenPlot, position: VisualGardenPlotPosition, size: CGSize) -> some View {
        Button {
            handleTap(plot)
        } label: {
            plotVisual(plot)
        }
        .buttonStyle(.plain)
        .position(
            x: size.width * position.x,
            y: size.height * position.y
        )
    }

    private func plotVisual(_ plot: VisualGardenPlot) -> some View {
        let selected = selectedPlotID == plot.id
        let sparkling = sparklePlotID == plot.id

        return ZStack {
            Ellipse()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.22, green: 0.13, blue: 0.07),
                            Color(red: 0.10, green: 0.07, blue: 0.04)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: scaled(92), height: scaled(36))
                .overlay(
                    Ellipse()
                        .strokeBorder(selected ? accent.opacity(0.95) : Color.white.opacity(0.12), lineWidth: selected ? 2 : 1)
                )
                .offset(y: scaled(29))

            plantImage(for: plot)
                .frame(width: scaled(86), height: scaled(86))
                .offset(y: scaled(-6))
                .scaleEffect(sparkling ? 1.12 : 1.0)
                .animation(.spring(response: 0.25, dampingFraction: 0.55), value: sparkling)

            if plot.isReady(today: todayOrdinal) {
                readyBadge
                    .offset(x: scaled(34), y: scaled(-32))
            }

            if plot.wateredDays.contains(todayOrdinal) {
                Image("item_water")
                    .resizable()
                    .scaledToFit()
                    .frame(width: scaled(20), height: scaled(20))
                    .offset(x: -scaled(34), y: scaled(24))
            }

            if sparkling {
                Image("fx_sparkle_1")
                    .resizable()
                    .scaledToFit()
                    .frame(width: scaled(92), height: scaled(92))
                    .opacity(0.9)
                    .offset(y: -scaled(18))
                    .transition(.opacity)
            }
        }
        .frame(width: scaled(112), height: scaled(118))
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private func plantImage(for plot: VisualGardenPlot) -> some View {
        if plot.crop == nil {
            Image(systemName: "plus")
                .font(.system(size: scaled(24), weight: .bold))
                .foregroundStyle(.white.opacity(0.22))
                .frame(width: scaled(58), height: scaled(58))
                .background(Circle().fill(Color.black.opacity(0.24)))
        } else {
            Image(plot.assetName(today: todayOrdinal))
                .resizable()
                .interpolation(.none)
                .scaledToFit()
                .shadow(color: plot.cropColor.opacity(0.42), radius: 10, x: 0, y: 4)
        }
    }

    private var readyBadge: some View {
        ZStack {
            Circle()
                .fill(accent)
                .frame(width: scaled(28), height: scaled(28))

            Image(systemName: "basket.fill")
                .font(.system(size: scaled(13), weight: .bold))
                .foregroundStyle(.black.opacity(0.78))
        }
    }

    private var actionDock: some View {
        VStack(spacing: scaled(10)) {
            if let selectedPlot {
                selectedPlotSummary(selectedPlot)
            }

            HStack(spacing: scaled(8)) {
                ForEach(VisualGardenAction.allCases) { action in
                    Button {
                        selectedAction = action
                        if let selectedPlot {
                            handleTap(selectedPlot)
                        }
                    } label: {
                        VStack(spacing: scaled(5)) {
                            Image(action.assetName)
                                .resizable()
                                .scaledToFit()
                                .frame(width: scaled(24), height: scaled(24))

                            Text(action.title)
                                .font(.system(size: scaled(10), weight: .bold))
                                .lineLimit(1)
                                .minimumScaleFactor(0.75)
                        }
                        .foregroundStyle(selectedAction == action ? .white : .white.opacity(0.58))
                        .frame(maxWidth: .infinity)
                        .frame(height: scaled(58))
                        .background(selectedAction == action ? action.color.opacity(0.28) : Color.white.opacity(0.055))
                        .clipShape(RoundedRectangle(cornerRadius: scaled(17), style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: scaled(17), style: .continuous)
                                .strokeBorder(selectedAction == action ? action.color.opacity(0.65) : Color.white.opacity(0.08), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(scaled(8))
            .background(Color.black.opacity(0.52))
            .clipShape(RoundedRectangle(cornerRadius: scaled(24), style: .continuous))
            .overlay(cardStroke(scaled(24)))
        }
    }

    private func selectedPlotSummary(_ plot: VisualGardenPlot) -> some View {
        HStack(spacing: scaled(12)) {
            VStack(alignment: .leading, spacing: scaled(3)) {
                Text(plot.title(today: todayOrdinal))
                    .font(.system(size: scaled(15), weight: .bold))
                    .foregroundStyle(.white)

                Text(plot.detail(today: todayOrdinal))
                    .font(.system(size: scaled(12), weight: .medium))
                    .foregroundStyle(.white.opacity(0.62))
                    .lineLimit(2)
            }

            Spacer()

            Text(selectedAction.title)
                .font(.system(size: scaled(12), weight: .bold))
                .foregroundStyle(selectedAction.color)
                .lineLimit(1)
                .minimumScaleFactor(0.78)
                .padding(.horizontal, scaled(10))
                .padding(.vertical, scaled(6))
                .background(selectedAction.color.opacity(0.16))
                .clipShape(Capsule())
        }
        .padding(scaled(13))
        .background(Color.black.opacity(0.50))
        .clipShape(RoundedRectangle(cornerRadius: scaled(20), style: .continuous))
        .overlay(cardStroke(scaled(20)))
    }

    private func cardStroke(_ radius: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: radius, style: .continuous)
            .strokeBorder(Color.white.opacity(0.09), lineWidth: 1)
    }
}

private extension VisualGardenView {
    var selectedPlot: VisualGardenPlot? {
        plots.first(where: { $0.id == selectedPlotID })
    }

    var todayOrdinal: Int {
        Calendar.current.ordinality(of: .day, in: .era, for: .now) ?? 0
    }

    var todayLogsCount: Int {
        allLogs.filter { Calendar.current.isDateInToday($0.date) }.count
    }

    var gardenLevel: Int {
        max(1, harvests / 4 + 1)
    }

    func handleTap(_ plot: VisualGardenPlot) {
        selectedPlotID = plot.id
        guard let index = plots.firstIndex(where: { $0.id == plot.id }) else { return }

        switch selectedAction {
        case .plant:
            guard plots[index].crop == nil else {
                showToast("Esse canteiro já tem uma planta.")
                return
            }
            plots[index].crop = .agabloom
            plots[index].plantedDay = todayOrdinal
            plots[index].wateredDays = []
            plots[index].boost = 0
            sparkle(plot.id)
            showToast("Semente plantada.")

        case .water:
            guard plots[index].crop != nil else {
                showToast("Plante uma semente primeiro.")
                return
            }
            guard water > 0 else {
                showToast("Você está sem água.")
                return
            }
            guard plots[index].wateredDays.contains(todayOrdinal) == false else {
                showToast("Esse canteiro já foi regado hoje.")
                return
            }
            water -= 1
            plots[index].wateredDays.append(todayOrdinal)
            sparkle(plot.id)
            showToast("A planta adorou a água.")

        case .sun:
            guard plots[index].crop != nil else {
                showToast("A luz precisa de uma planta.")
                return
            }
            guard sun > 0 else {
                showToast("Você está sem luz acumulada.")
                return
            }
            sun -= 1
            plots[index].boost += 1
            sparkle(plot.id)
            showToast("A planta brilhou mais forte.")

        case .fertilize:
            guard plots[index].crop != nil else {
                showToast("Adube depois de plantar.")
                return
            }
            guard fertilizer > 0 else {
                showToast("Você está sem adubo.")
                return
            }
            fertilizer -= 1
            plots[index].boost += 2
            sparkle(plot.id)
            showToast("Crescimento acelerado.")

        case .harvest:
            guard plots[index].isReady(today: todayOrdinal) else {
                showToast("Ainda não está pronta para colher.")
                return
            }
            harvests += 1
            plots[index] = VisualGardenPlot.empty(id: plot.id)
            sparkle(plot.id)
            showToast("Colheita feita. Seu jardim cresceu.")
        }
    }

    func claimDailyRewardIfNeeded() {
        guard lastRewardDay != todayOrdinal else { return }
        water += 5 + todayLogsCount
        sun += max(1, todayLogsCount / 2)
        fertilizer += todayLogsCount >= 3 ? 1 : 0
        lastRewardDay = todayOrdinal
    }

    func loadPlots() {
        guard
            encodedPlots.isEmpty == false,
            let data = encodedPlots.data(using: .utf8),
            let decoded = try? JSONDecoder().decode([VisualGardenPlot].self, from: data),
            decoded.count == VisualGardenPlot.defaultPlots.count
        else {
            plots = VisualGardenPlot.defaultPlots
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

    func sparkle(_ plotID: Int) {
        withAnimation(.spring(response: 0.25, dampingFraction: 0.62)) {
            sparklePlotID = plotID
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.36) {
            withAnimation(.easeOut(duration: 0.18)) {
                if sparklePlotID == plotID {
                    sparklePlotID = nil
                }
            }
        }
    }

    func showToast(_ message: String) {
        withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
            toast = message
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeOut(duration: 0.18)) {
                if toast == message {
                    toast = nil
                }
            }
        }
    }
}

private enum VisualGardenAction: String, CaseIterable, Identifiable {
    case plant
    case water
    case sun
    case fertilize
    case harvest

    var id: String { rawValue }

    var title: String {
        switch self {
        case .plant: return "Plantar"
        case .water: return "Regar"
        case .sun: return "Luz"
        case .fertilize: return "Adubar"
        case .harvest: return "Colher"
        }
    }

    var assetName: String {
        switch self {
        case .plant: return "agabloom_seed"
        case .water: return "item_water"
        case .sun: return "item_sun"
        case .fertilize: return "item_fertilizer"
        case .harvest: return "agabloom_bloom"
        }
    }

    var color: Color {
        switch self {
        case .plant: return Color(red: 0.39, green: 0.88, blue: 0.28)
        case .water: return Color(red: 0.24, green: 0.62, blue: 1.0)
        case .sun: return .yellow
        case .fertilize: return Color(red: 0.72, green: 0.48, blue: 0.24)
        case .harvest: return Color(red: 0.28, green: 1.0, blue: 0.55)
        }
    }
}

private enum VisualCrop: String, Codable {
    case agabloom
}

private struct VisualGardenPlot: Codable, Identifiable, Equatable {
    let id: Int
    var crop: VisualCrop?
    var plantedDay: Int?
    var wateredDays: [Int]
    var boost: Int

    static var defaultPlots: [VisualGardenPlot] {
        (0..<7).map { VisualGardenPlot.empty(id: $0) }
    }

    static func empty(id: Int) -> VisualGardenPlot {
        VisualGardenPlot(id: id, crop: nil, plantedDay: nil, wateredDays: [], boost: 0)
    }

    var cropColor: Color {
        Color(red: 0.39, green: 0.88, blue: 0.28)
    }

    func maturity(today: Int) -> Int {
        guard crop != nil else { return 0 }
        return min(Set(wateredDays).count + boost, 4)
    }

    func assetName(today: Int) -> String {
        switch maturity(today: today) {
        case 0: return "agabloom_seed"
        case 1: return "agabloom_sprout"
        case 2: return "agabloom_small"
        case 3: return "agabloom_medium"
        default: return "agabloom_bloom"
        }
    }

    func isReady(today: Int) -> Bool {
        maturity(today: today) >= 4
    }

    func title(today: Int) -> String {
        guard crop != nil else { return "Canteiro vazio" }
        if isReady(today: today) { return "AgaBloom pronta" }
        return "AgaBloom crescendo"
    }

    func detail(today: Int) -> String {
        guard crop != nil else {
            return "Plante uma semente para começar."
        }

        if isReady(today: today) {
            return "Pronta para colher. Toque em Colher para liberar espaço."
        }

        let remaining = max(4 - maturity(today: today), 0)
        return "Faltam \(remaining) cuidados para florescer."
    }
}

private struct VisualGardenPlotPosition: Identifiable {
    let id: Int
    let x: CGFloat
    let y: CGFloat

    static let all: [VisualGardenPlotPosition] = [
        .init(id: 0, x: 0.24, y: 0.44),
        .init(id: 1, x: 0.48, y: 0.40),
        .init(id: 2, x: 0.73, y: 0.45),
        .init(id: 3, x: 0.35, y: 0.57),
        .init(id: 4, x: 0.61, y: 0.58),
        .init(id: 5, x: 0.22, y: 0.70),
        .init(id: 6, x: 0.76, y: 0.71)
    ]
}
