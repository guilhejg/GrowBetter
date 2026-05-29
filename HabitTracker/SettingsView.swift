import SwiftUI

enum HTInterfaceScaleLevel: Double, CaseIterable, Identifiable {
    case compact = 0.75
    case comfortable = 0.85
    case large = 1.0

    var id: Double { rawValue }

    var title: String {
        switch self {
        case .compact: return "Compacto"
        case .comfortable: return "Confortável"
        case .large: return "Grande"
        }
    }

    var subtitle: String {
        switch self {
        case .compact: return "Mais conteúdo na tela"
        case .comfortable: return "Equilíbrio entre espaço e leitura"
        case .large: return "Elementos no tamanho máximo"
        }
    }

    var percentText: String {
        "\(Int(rawValue * 100))%"
    }

    var summary: String {
        "\(title) (\(percentText))"
    }

    static func nearest(to value: Double) -> HTInterfaceScaleLevel {
        allCases.min { lhs, rhs in
            abs(lhs.rawValue - value) < abs(rhs.rawValue - value)
        } ?? .comfortable
    }
}

struct SettingsView: View {
    @AppStorage("appearance.uiScale") private var uiScale: Double = 0.85
    @AppStorage("settings.darkMode") private var darkMode = true
    @AppStorage("settings.notifications") private var notificationsEnabled = true
    @AppStorage("settings.cloudSync") private var cloudSyncEnabled = false
    @AppStorage("garden.presentationStyle") private var gardenStyle: GardenPresentationStyle = .visual

    private let accent = Color(red: 0.39, green: 0.88, blue: 0.28)

    private var scale: CGFloat {
        CGFloat(min(max(uiScale, 0.75), 1.0))
    }

    private func scaled(_ value: CGFloat) -> CGFloat {
        value * scale
    }

    var body: some View {
        NavigationStack {
            ZStack {
                background

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: scaled(22)) {
                        header

                        settingsSection("CONTA") {
                            settingsRow(icon: "person.fill", title: "Perfil", subtitle: "Gerencie suas informações")
                            divider
                            settingsRow(icon: "shield.fill", title: "Segurança", subtitle: "Senha, Face ID e privacidade")
                            divider
                            settingsRow(
                                icon: "icloud.fill",
                                title: "Sincronização",
                                subtitle: "Cópia de segurança e dados na nuvem",
                                trailing: cloudSyncEnabled ? "Ativo" : "Inativo"
                            )
                        }

                        settingsSection("PREFERÊNCIAS") {
                            toggleRow(
                                icon: "bell.fill",
                                title: "Notificações",
                                subtitle: "Gerencie lembretes e alertas",
                                isOn: $notificationsEnabled
                            )
                            divider
                            gardenRow
                            divider
                            scaleRow
                            divider
                            toggleRow(
                                icon: "moon.fill",
                                title: "Modo escuro",
                                subtitle: darkMode ? "Ativado" : "Desativado",
                                isOn: $darkMode
                            )
                            divider
                            settingsRow(icon: "globe", title: "Idioma", subtitle: "Português (Brasil)")
                        }

                        settingsSection("GERAL") {
                            settingsRow(icon: "questionmark.circle.fill", title: "Central de ajuda", subtitle: "Dúvidas frequentes e suporte")
                            divider
                            settingsRow(icon: "star.fill", title: "Avaliar o app", subtitle: "Sua opinião é importante")
                            divider
                            settingsRow(icon: "square.and.arrow.up", title: "Compartilhar o HabitTracker", subtitle: "Convide amigos para cultivar")
                            divider
                            settingsRow(icon: "info.circle.fill", title: "Sobre o HabitTracker", subtitle: "Versão 1.0.0")
                        }

                        Button {
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                    .font(.system(size: scaled(20), weight: .semibold))
                                Text("Sair da conta")
                                    .font(.system(size: scaled(17), weight: .semibold))
                            }
                            .foregroundStyle(Color(red: 1.0, green: 0.32, blue: 0.28))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, scaled(18))
                            .background(cardFill)
                            .clipShape(RoundedRectangle(cornerRadius: scaled(22), style: .continuous))
                            .overlay(cardStroke(cornerRadius: scaled(22)))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, scaled(18))
                    .padding(.top, scaled(18))
                    .padding(.bottom, scaled(28))
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .preferredColorScheme(.dark)
            .onAppear(perform: normalizeScale)
        }
    }

    private var background: some View {
        ZStack {
            Color(red: 0.01, green: 0.03, blue: 0.035)
                .ignoresSafeArea()

            LinearGradient(
                colors: [
                    Color.green.opacity(0.10),
                    Color.clear,
                    Color.blue.opacity(0.04)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Ajustes")
                    .font(.system(size: scaled(34), weight: .bold))
                    .foregroundStyle(.white)

                Text("Personalize sua experiência no HabitTracker.")
                    .font(.system(size: scaled(16), weight: .medium))
                    .foregroundStyle(.white.opacity(0.62))
            }

            Spacer()

            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.06))
                    .frame(width: scaled(64), height: scaled(64))
                    .overlay(Circle().strokeBorder(Color.white.opacity(0.08), lineWidth: 1))

                Image(systemName: "leaf.fill")
                    .font(.system(size: scaled(28), weight: .bold))
                    .foregroundStyle(accent)
            }
        }
    }

    private func settingsSection<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: scaled(10)) {
            Text(title)
                .font(.system(size: scaled(14), weight: .semibold))
                .foregroundStyle(.white.opacity(0.58))
                .padding(.leading, scaled(4))

            VStack(spacing: 0) {
                content()
            }
            .padding(.horizontal, scaled(14))
            .padding(.vertical, scaled(10))
            .background(cardFill)
            .clipShape(RoundedRectangle(cornerRadius: scaled(22), style: .continuous))
            .overlay(cardStroke(cornerRadius: scaled(22)))
        }
    }

    private func settingsRow(icon: String, title: String, subtitle: String, trailing: String? = nil) -> some View {
        HStack(spacing: scaled(14)) {
            iconTile(icon)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: scaled(17), weight: .semibold))
                    .foregroundStyle(.white)

                Text(subtitle)
                    .font(.system(size: scaled(14), weight: .medium))
                    .foregroundStyle(.white.opacity(0.58))
            }

            Spacer()

            if let trailing {
                Text(trailing)
                    .font(.system(size: scaled(15), weight: .semibold))
                    .foregroundStyle(trailing == "Ativo" ? accent : .white.opacity(0.45))
            }

            Image(systemName: "chevron.right")
                .font(.system(size: scaled(15), weight: .semibold))
                .foregroundStyle(.white.opacity(0.48))
        }
        .padding(.vertical, scaled(10))
        .contentShape(Rectangle())
    }

    private func toggleRow(icon: String, title: String, subtitle: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: scaled(14)) {
            iconTile(icon)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: scaled(17), weight: .semibold))
                    .foregroundStyle(.white)

                Text(subtitle)
                    .font(.system(size: scaled(14), weight: .medium))
                    .foregroundStyle(.white.opacity(0.58))
            }

            Spacer()

            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(accent)
        }
        .padding(.vertical, scaled(10))
    }

    private var scaleRow: some View {
        NavigationLink {
            ScaleSettingsView()
        } label: {
            settingsRow(
                icon: "textformat.size",
                title: "Escala",
                subtitle: "Tamanho da interface",
                trailing: scaleLevel.summary
            )
        }
        .buttonStyle(.plain)
    }

    private var gardenRow: some View {
        NavigationLink {
            GardenSettingsView()
        } label: {
            settingsRow(
                icon: "leaf.fill",
                title: "Jardim",
                subtitle: "Aparência e modo de exibição",
                trailing: gardenStyle.title
            )
        }
        .buttonStyle(.plain)
    }

    private var scaleLevel: HTInterfaceScaleLevel {
        HTInterfaceScaleLevel.nearest(to: uiScale)
    }

    private func normalizeScale() {
        let normalized = scaleLevel.rawValue
        if abs(uiScale - normalized) > 0.001 {
            uiScale = normalized
        }
    }

    private func iconTile(_ icon: String) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(accent.opacity(0.15))
                .frame(width: scaled(42), height: scaled(42))

            Image(systemName: icon)
                .font(.system(size: scaled(18), weight: .semibold))
                .foregroundStyle(accent)
        }
    }

    private var divider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.08))
            .frame(height: 1)
            .padding(.leading, scaled(56))
    }

    private var cardFill: some ShapeStyle {
        LinearGradient(
            colors: [
                Color.white.opacity(0.07),
                Color.white.opacity(0.04)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private func cardStroke(cornerRadius: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
    }
}

private struct GardenSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("appearance.uiScale") private var uiScale: Double = 0.85
    @AppStorage("garden.presentationStyle") private var gardenStyle: GardenPresentationStyle = .visual

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
                VStack(alignment: .leading, spacing: scaled(22)) {
                    header

                    VStack(spacing: 0) {
                        ForEach(GardenPresentationStyle.allCases) { style in
                            Button {
                                gardenStyle = style
                            } label: {
                                optionRow(style)
                            }
                            .buttonStyle(.plain)

                            if style.id != GardenPresentationStyle.allCases.last?.id {
                                divider
                            }
                        }
                    }
                    .padding(.horizontal, scaled(14))
                    .padding(.vertical, scaled(10))
                    .background(cardFill)
                    .clipShape(RoundedRectangle(cornerRadius: scaled(22), style: .continuous))
                    .overlay(cardStroke(cornerRadius: scaled(22)))

                    noteCard
                }
                .padding(.horizontal, scaled(18))
                .padding(.top, scaled(18))
                .padding(.bottom, scaled(28))
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .preferredColorScheme(.dark)
    }

    private var background: some View {
        ZStack {
            Color(red: 0.01, green: 0.03, blue: 0.035)
                .ignoresSafeArea()

            LinearGradient(
                colors: [
                    Color.green.opacity(0.10),
                    Color.clear,
                    Color.blue.opacity(0.04)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: scaled(12)) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: scaled(18), weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: scaled(44), height: scaled(44))
                    .background(Color.white.opacity(0.06))
                    .clipShape(Circle())
                    .overlay(Circle().strokeBorder(Color.white.opacity(0.08), lineWidth: 1))
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 6) {
                Text("Jardim")
                    .font(.system(size: scaled(34), weight: .bold))
                    .foregroundStyle(.white)

                Text("Escolha como a aba Jardim será exibida.")
                    .font(.system(size: scaled(16), weight: .medium))
                    .foregroundStyle(.white.opacity(0.62))
                    .lineLimit(2)
            }

            Spacer()
        }
    }

    private func optionRow(_ style: GardenPresentationStyle) -> some View {
        HStack(spacing: scaled(14)) {
            ZStack {
                RoundedRectangle(cornerRadius: scaled(12), style: .continuous)
                    .fill(accent.opacity(style == gardenStyle ? 0.22 : 0.12))
                    .frame(width: scaled(42), height: scaled(42))

                Image(systemName: style == .visual ? "photo.fill" : "square.grid.3x3.fill")
                    .font(.system(size: scaled(17), weight: .bold))
                    .foregroundStyle(accent)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(style.title)
                    .font(.system(size: scaled(17), weight: .semibold))
                    .foregroundStyle(.white)

                Text(style.subtitle)
                    .font(.system(size: scaled(14), weight: .medium))
                    .foregroundStyle(.white.opacity(0.58))
            }

            Spacer()

            Image(systemName: style == gardenStyle ? "checkmark.circle.fill" : "circle")
                .font(.system(size: scaled(22), weight: .semibold))
                .foregroundStyle(style == gardenStyle ? accent : .white.opacity(0.28))
        }
        .padding(.vertical, scaled(10))
        .contentShape(Rectangle())
    }

    private var noteCard: some View {
        HStack(spacing: scaled(12)) {
            Image(systemName: "eye.slash.fill")
                .font(.system(size: scaled(20), weight: .bold))
                .foregroundStyle(accent)
                .frame(width: scaled(44), height: scaled(44))
                .background(accent.opacity(0.14))
                .clipShape(RoundedRectangle(cornerRadius: scaled(14), style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text("A aba Jardim fica limpa")
                    .font(.system(size: scaled(17), weight: .semibold))
                    .foregroundStyle(.white)

                Text("A troca de estilo aparece só aqui nos Ajustes.")
                    .font(.system(size: scaled(14), weight: .medium))
                    .foregroundStyle(.white.opacity(0.58))
                    .lineLimit(2)
            }
        }
        .padding(scaled(16))
        .background(cardFill)
        .clipShape(RoundedRectangle(cornerRadius: scaled(22), style: .continuous))
        .overlay(cardStroke(cornerRadius: scaled(22)))
    }

    private var divider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.08))
            .frame(height: 1)
            .padding(.leading, scaled(56))
    }

    private var cardFill: some ShapeStyle {
        LinearGradient(
            colors: [
                Color.white.opacity(0.07),
                Color.white.opacity(0.04)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private func cardStroke(cornerRadius: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
    }
}

private struct ScaleSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("appearance.uiScale") private var uiScale: Double = 0.85

    private let accent = Color(red: 0.39, green: 0.88, blue: 0.28)

    private var scale: CGFloat {
        CGFloat(min(max(uiScale, 0.75), 1.0))
    }

    private func scaled(_ value: CGFloat) -> CGFloat {
        value * scale
    }

    private var selectedLevel: HTInterfaceScaleLevel {
        HTInterfaceScaleLevel.nearest(to: uiScale)
    }

    var body: some View {
        ZStack {
            background

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: scaled(22)) {
                    header

                    VStack(spacing: 0) {
                        ForEach(HTInterfaceScaleLevel.allCases) { level in
                            Button {
                                uiScale = level.rawValue
                            } label: {
                                optionRow(level)
                            }
                            .buttonStyle(.plain)

                            if level.id != HTInterfaceScaleLevel.allCases.last?.id {
                                divider
                            }
                        }
                    }
                    .padding(.horizontal, scaled(14))
                    .padding(.vertical, scaled(10))
                    .background(cardFill)
                    .clipShape(RoundedRectangle(cornerRadius: scaled(22), style: .continuous))
                    .overlay(cardStroke(cornerRadius: scaled(22)))

                    previewCard
                }
                .padding(.horizontal, scaled(18))
                .padding(.top, scaled(18))
                .padding(.bottom, scaled(28))
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .preferredColorScheme(.dark)
    }

    private var background: some View {
        ZStack {
            Color(red: 0.01, green: 0.03, blue: 0.035)
                .ignoresSafeArea()

            LinearGradient(
                colors: [
                    Color.green.opacity(0.10),
                    Color.clear,
                    Color.blue.opacity(0.04)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: scaled(12)) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: scaled(18), weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: scaled(44), height: scaled(44))
                    .background(Color.white.opacity(0.06))
                    .clipShape(Circle())
                    .overlay(Circle().strokeBorder(Color.white.opacity(0.08), lineWidth: 1))
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 6) {
                Text("Escala")
                    .font(.system(size: scaled(34), weight: .bold))
                    .foregroundStyle(.white)

                Text("Escolha o tamanho da interface do app.")
                    .font(.system(size: scaled(16), weight: .medium))
                    .foregroundStyle(.white.opacity(0.62))
            }

            Spacer()
        }
    }

    private func optionRow(_ level: HTInterfaceScaleLevel) -> some View {
        HStack(spacing: scaled(14)) {
            ZStack {
                RoundedRectangle(cornerRadius: scaled(12), style: .continuous)
                    .fill(accent.opacity(level == selectedLevel ? 0.22 : 0.12))
                    .frame(width: scaled(42), height: scaled(42))

                Text(level.percentText)
                    .font(.system(size: scaled(12), weight: .bold))
                    .foregroundStyle(accent)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(level.title)
                    .font(.system(size: scaled(17), weight: .semibold))
                    .foregroundStyle(.white)

                Text(level.subtitle)
                    .font(.system(size: scaled(14), weight: .medium))
                    .foregroundStyle(.white.opacity(0.58))
            }

            Spacer()

            Image(systemName: level == selectedLevel ? "checkmark.circle.fill" : "circle")
                .font(.system(size: scaled(22), weight: .semibold))
                .foregroundStyle(level == selectedLevel ? accent : .white.opacity(0.28))
        }
        .padding(.vertical, scaled(10))
        .contentShape(Rectangle())
    }

    private var previewCard: some View {
        VStack(alignment: .leading, spacing: scaled(12)) {
            Text("Prévia")
                .font(.system(size: scaled(18), weight: .bold))
                .foregroundStyle(.white)

            HStack(spacing: scaled(12)) {
                Image(systemName: "leaf.fill")
                    .font(.system(size: scaled(24), weight: .bold))
                    .foregroundStyle(accent)
                    .frame(width: scaled(46), height: scaled(46))
                    .background(accent.opacity(0.14))
                    .clipShape(RoundedRectangle(cornerRadius: scaled(14), style: .continuous))

                VStack(alignment: .leading, spacing: 3) {
                    Text(selectedLevel.summary)
                        .font(.system(size: scaled(17), weight: .semibold))
                        .foregroundStyle(.white)

                    Text("Essa escala será aplicada em todas as abas.")
                        .font(.system(size: scaled(14), weight: .medium))
                        .foregroundStyle(.white.opacity(0.58))
                }
            }
        }
        .padding(scaled(16))
        .background(cardFill)
        .clipShape(RoundedRectangle(cornerRadius: scaled(22), style: .continuous))
        .overlay(cardStroke(cornerRadius: scaled(22)))
    }

    private var divider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.08))
            .frame(height: 1)
            .padding(.leading, scaled(56))
    }

    private var cardFill: some ShapeStyle {
        LinearGradient(
            colors: [
                Color.white.opacity(0.07),
                Color.white.opacity(0.04)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private func cardStroke(cornerRadius: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
    }
}
