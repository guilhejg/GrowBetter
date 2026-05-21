import SwiftUI
import SwiftData

struct AgaBloomSceneView: View {

    // ✅ Ajuste a imagem de fundo aqui (nome no Assets)
    private let backgroundAssetName = "bg_golden_brown"

    // ✅ Animação leve quando marca hábito (pulse)
    @State private var pulse = false
    @State private var sparkleToggle = false

    // ✅ Topbar “gambiarra” (ajuste fino se precisar)
    private let topBarExtraInset: CGFloat = 56

    // =========================================================
    // ✅ BUSCA DOS LOGS (SwiftData)
    // =========================================================
    @Query(sort: \HTHabitLog.date, order: .forward)
    private var allLogs: [HTHabitLog]

    // =========================================================
    // ✅ COORDENADAS FIXAS (as que você fechou)
    // =========================================================

    // Planta
    private let plantOffsetX: CGFloat = 3
    private let plantOffsetY: CGFloat = 69
    private let plantWidth: CGFloat = 240
    private let plantScale: CGFloat = 1.0

    // Sombra
    private let shadowOffsetX: CGFloat = 26
    private let shadowOffsetY: CGFloat = 143
    private let shadowScale: CGFloat = 1.32
    private let shadowOpacity: CGFloat = 0.55

    // FX
    private let fxEnabled: Bool = false
    private let fxOffsetX: CGFloat = -69
    private let fxOffsetY: CGFloat = 6
    private let fxScale: CGFloat = 0.2
    private let fxOpacity: CGFloat = 0.75

    // Texto
    private let textOffsetX: CGFloat = 20
    private let textOffsetY: CGFloat = +65
    private let textSize: CGFloat = 16
    private let textOpacity: CGFloat = 0.00

    var body: some View {
        GeometryReader { geo in
            let safeTop = geo.safeAreaInsets.top
            let topTotal = HTConstants.topBarHeight + safeTop

            // ✅ total de completions (modo recomendado: 1 por dia)
            let totalCompletions = totalUniqueDaysCompleted()

            // ✅ nível e sprite via AgaBloomProgress
            let level = AgaBloomProgress.level(for: totalCompletions)
            let plantAsset = AgaBloomProgress.imageName(for: level)
            let stageLabel = labelForLevel(level)

            ZStack(alignment: .top) {

                // ✅ BACKGROUND
                Image(backgroundAssetName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
                    .ignoresSafeArea()

                // ✅ CAMADA CENTRAL (planta/sombra/fx/texto)
                centerContent(
                    plantAsset: plantAsset,
                    stageLabel: stageLabel
                )
                .frame(width: geo.size.width, height: geo.size.height)
                .allowsHitTesting(false)

                // ✅ TOPBAR (com retângulo invisível)
                topBar(
                    safeTop: safeTop,
                    topTotal: topTotal,
                    stageLabel: stageLabel
                )
                .frame(maxWidth: .infinity)
                .background(Color.clear)
            }
            .onReceive(NotificationCenter.default.publisher(for: .agaBloomPulse)) { _ in
                playPulse()
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    // MARK: - Center content

    private func centerContent(plantAsset: String, stageLabel: String) -> some View {
        VStack(spacing: 0) {
            Spacer()

            ZStack {
                // Sombra
                Image("shadow_soft")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 180)
                    .scaleEffect(shadowScale)
                    .opacity(shadowOpacity)
                    .offset(x: shadowOffsetX, y: shadowOffsetY)

                // Planta
                Image(plantAsset)
                    .resizable()
                    .interpolation(.none)
                    .scaledToFit()
                    .frame(width: plantWidth)
                    .scaleEffect((pulse ? 1.03 : 1.0) * plantScale)
                    .offset(x: plantOffsetX, y: plantOffsetY)
                    .animation(.spring(response: 0.25, dampingFraction: 0.6), value: pulse)

                // FX
                if fxEnabled {
                    let fxName = sparkleToggle ? "fx_sparkle_1" : "fx_sparkle_2"
                    Image(fxName)
                        .resizable()
                        .interpolation(.none)
                        .scaledToFit()
                        .frame(width: 220)
                        .scaleEffect(fxScale)
                        .opacity(fxOpacity)
                        .offset(x: fxOffsetX, y: fxOffsetY)
                }
            }

            Text(stageLabel)
                .font(.system(size: textSize, weight: .semibold))
                .foregroundStyle(.white.opacity(textOpacity))
                .offset(x: textOffsetX, y: textOffsetY)

            Spacer()
        }
    }

    // MARK: - Top Bar

    private func topBar(safeTop: CGFloat, topTotal: CGFloat, stageLabel: String) -> some View {
        VStack(spacing: 0) {

            // ✅ retângulo invisível pra empurrar pra baixo (iOS 26)
            Color.clear
                .frame(height: safeTop + topBarExtraInset)

            HStack(spacing: 12) {
                Circle()
                    .fill(Color.white.opacity(0.10))
                    .frame(width: HTConstants.topIconSize, height: HTConstants.topIconSize)
                    .overlay(
                        Image(systemName: "leaf.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.9))
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text("AgaBloom")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.white)

                    Text(stageLabel)
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.65))
                }

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)

            Spacer(minLength: 0)
        }
        .frame(height: topTotal + topBarExtraInset)
    }

    // MARK: - Progresso baseado em completions

    /// ✅ Recomendado: 1 completion por dia (não “farmar” marcando vários hábitos)
    private func totalUniqueDaysCompleted() -> Int {
        let cal = Calendar.current
        let uniqueDays = Set(allLogs.map { cal.startOfDay(for: $0.date) })
        return uniqueDays.count
    }

    /// Alternativa: total de logs (pode “farmar” marcando vários hábitos no mesmo dia)
    private func totalLogsCompleted() -> Int {
        allLogs.count
    }

    // MARK: - Label

    private func labelForLevel(_ level: Int) -> String {
        switch level {
        case 0: return "Semente"
        case 1: return "Broto"
        case 2: return "Pequena"
        case 3: return "Média"
        case 4: return "Grande"
        default: return "Bloom"
        }
    }

    // MARK: - Pulse

    private func playPulse() {
        pulse = true
        sparkleToggle.toggle()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
            pulse = false
        }
    }
}
