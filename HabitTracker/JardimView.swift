import SwiftUI

struct JardimView: View {

    @AppStorage("agaBloomStage") private var stage: Int = 0

    // ✅ Pulso visual quando marcar hábito
    @State private var pulse: Bool = false

    // =========================================================
    // ✅ BACKGROUND TUNER (salva automaticamente em AppStorage)
    // =========================================================
    @AppStorage("bgOffsetX") private var bgOffsetX: Double = 0
    @AppStorage("bgOffsetY") private var bgOffsetY: Double = 0
    @AppStorage("bgScale")   private var bgScale: Double = 1.2

    @State private var showingBackgroundTuner: Bool = false

    // =========================================================
    // ✅ POSIÇÃO FIXA DA PLANTA (como você fechou)
    // =========================================================
    private let plantFixedOffsetX: CGFloat = -14
    private let plantFixedOffsetY: CGFloat = 25
    private let plantWidth: CGFloat = 190

    // ✅ Controle simples do “encaixe” do título
    private let topTitleExtraInset: CGFloat = 12

    var body: some View {
        GeometryReader { geo in
            let safeTop = geo.safeAreaInsets.top

            ZStack {

                // =========================================================
                // ✅ BACKGROUND CORRETO: não limita com frame do geo
                //    (assim ele consegue ir “atrás” da TabBar também)
                // =========================================================
                backgroundLayer

                // sombra suave (opcional)
                Image("shadow_soft")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 220)
                    .opacity(0.55)
                    .position(
                        x: geo.size.width * 0.5,
                        y: geo.size.height * 0.62
                    )

                // ✅ AgaBloom (posição fixa)
                Image(stageAssetName)
                    .resizable()
                    .interpolation(.none)
                    .scaledToFit()
                    .frame(width: plantWidth)
                    .position(x: geo.size.width / 2, y: geo.size.height / 2)
                    .offset(x: plantFixedOffsetX, y: plantFixedOffsetY)

                // ✅ Pulse FX
                if pulse {
                    ZStack {
                        Image("fx_sparkle_1")
                            .resizable()
                            .interpolation(.none)
                            .scaledToFit()
                            .frame(width: 120)
                            .opacity(0.9)
                            .offset(x: -40, y: -40)

                        Image("fx_sparkle_2")
                            .resizable()
                            .interpolation(.none)
                            .scaledToFit()
                            .frame(width: 130)
                            .opacity(0.9)
                            .offset(x: 45, y: -20)
                    }
                    .position(x: geo.size.width * 0.5, y: geo.size.height * 0.54)
                    .transition(.opacity)
                }

                // Texto do estágio (central)
                Text(stageLabel)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.80))
                    .shadow(radius: 10)
                    .position(x: geo.size.width * 0.5, y: geo.size.height * 0.70)

                // =========================================================
                // ✅ Topbar
                // =========================================================
                VStack(alignment: .leading, spacing: 0) {

                    Color.clear
                        .frame(height: safeTop + topTitleExtraInset)

                    HStack(spacing: 10) {
                        Image(systemName: "leaf.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.92))
                            .frame(width: 36, height: 36)
                            .background(Circle().fill(Color.black.opacity(0.25)))

                        VStack(alignment: .leading, spacing: 2) {
                            Text("AgaBloom")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundStyle(.white)

                            Text(stageLabel)
                                .font(.system(size: 13))
                                .foregroundStyle(.white.opacity(0.70))
                        }

                        Spacer()

                        // ✅ botão do tuner do BACKGROUND
                        Button {
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
                                showingBackgroundTuner.toggle()
                            }
                        } label: {
                            Image(systemName: "slider.horizontal.3")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.92))
                                .frame(width: 36, height: 36)
                                .background(Circle().fill(Color.black.opacity(0.25)))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 16)

                    Spacer()
                }

                // ✅ Painel do tuner
                if showingBackgroundTuner {
                    backgroundTunerPanel
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .agaBloomPulse)) { _ in
                triggerPulse()
            }
        }
    }

    // =========================================================
    // MARK: - Background (isolado e “livre” do frame do geo)
    // =========================================================
    private var backgroundLayer: some View {
        Image("bg_golden_brown")
            .resizable()
            .scaledToFill()
            .scaleEffect(bgScale)
            .offset(x: bgOffsetX, y: bgOffsetY)
            .ignoresSafeArea()     // ✅ vai atrás da TabBar e atrás do notch
            .clipped()             // ✅ garante que não “vaze” em rotações
    }

    // =========================================================
    // MARK: - Background Tuner Panel (SEPARADO PRA REUSAR DEPOIS)
    // =========================================================
    private var backgroundTunerPanel: some View {
        VStack {
            Spacer()

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Ajuste do background")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.9))

                    Spacer()

                    Button("Reset") {
                        bgOffsetX = 0
                        bgOffsetY = 0
                        bgScale = 1.0
                    }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.9))
                }

                tunerRow(
                    title: "X",
                    valueText: "\(Int(bgOffsetX))",
                    value: Binding(get: { bgOffsetX }, set: { bgOffsetX = $0 }),
                    range: -400...400
                )

                tunerRow(
                    title: "Y",
                    valueText: "\(Int(bgOffsetY))",
                    value: Binding(get: { bgOffsetY }, set: { bgOffsetY = $0 }),
                    range: -400...400
                )

                tunerRow(
                    title: "Zoom",
                    valueText: String(format: "%.2f", bgScale),
                    value: Binding(get: { bgScale }, set: { bgScale = $0 }),
                    range: 0.8...2.2
                )

                Text("Esses valores ficam salvos. Ajuste até preencher certinho (inclusive atrás da TabBar).")
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.65))
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.black.opacity(0.45))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
            )
            .padding(.horizontal, 14)
            .padding(.bottom, 18)
        }
    }

    private func tunerRow(
        title: String,
        valueText: String,
        value: Binding<Double>,
        range: ClosedRange<Double>
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.85))
                Spacer()
                Text(valueText)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.70))
            }
            Slider(value: value, in: range)
        }
    }

    // MARK: - Pulse

    private func triggerPulse() {
        withAnimation(.easeOut(duration: 0.12)) {
            pulse = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            withAnimation(.easeOut(duration: 0.20)) {
                pulse = false
            }
        }
    }

    // MARK: - Stage mapping

    private var stageAssetName: String {
        switch stage {
        case 0: return "agabloom_seed"
        case 1: return "agabloom_sprout"
        case 2: return "agabloom_small"
        case 3: return "agabloom_medium"
        case 4: return "agabloom_big"
        default: return "agabloom_bloom"
        }
    }

    private var stageLabel: String {
        switch stage {
        case 0: return "Semente"
        case 1: return "Broto"
        case 2: return "Pequena"
        case 3: return "Crescendo"
        case 4: return "Grande"
        default: return "Bloom 🌸"
        }
    }
}
