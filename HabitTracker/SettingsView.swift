import SwiftUI

// MARK: - SettingsView (iOS Settings style)

struct SettingsView: View {

    // MARK: - "Perfil" (placeholder por enquanto)
    @State private var displayName: String = "João Guilherme"
    @State private var subtitle: String = "Conta HabitTracker"
    @State private var profileImage: Image? = nil

    // MARK: - Preferências do app
    @State private var remindersEnabled: Bool = true
    @State private var soundEnabled: Bool = true
    @State private var confettiEnabled: Bool = true

    @State private var theme: AppTheme = .system
    @State private var hapticsEnabled: Bool = true

    @State private var iCloudSyncEnabled: Bool = false
    @State private var analyticsEnabled: Bool = false

    var body: some View {
        NavigationStack {
            List {
                // Top Profile Card
                Section {
                    profileRow
                }

                // Notificações
                Section {
                    NavigationLink {
                        NotificationsSettingsView(
                            remindersEnabled: $remindersEnabled,
                            soundEnabled: $soundEnabled
                        )
                    } label: {
                        SettingsRow(
                            icon: "bell.fill",
                            tint: .red,
                            title: "Notificações",
                            subtitle: remindersEnabled ? "Ativadas" : "Desativadas"
                        )
                    }

                    Toggle(isOn: $confettiEnabled) {
                        SettingsRow(
                            icon: "sparkles",
                            tint: .yellow,
                            title: "Confete ao concluir",
                            subtitle: "Animação ao marcar hábito"
                        )
                    }
                } header: {
                    Text("LEMBRETES")
                }

                // Aparência
                Section {
                    NavigationLink {
                        AppearanceSettingsView(
                            theme: $theme,
                            hapticsEnabled: $hapticsEnabled
                        )
                    } label: {
                        SettingsRow(
                            icon: "paintbrush.fill",
                            tint: .blue,
                            title: "Aparência",
                            subtitle: theme.displayName
                        )
                    }
                } header: {
                    Text("APARÊNCIA")
                }

                // Dados e backup
                Section {
                    Toggle(isOn: $iCloudSyncEnabled) {
                        SettingsRow(
                            icon: "icloud.fill",
                            tint: .cyan,
                            title: "Sincronizar com iCloud",
                            subtitle: iCloudSyncEnabled ? "Ativado" : "Desativado"
                        )
                    }

                    NavigationLink {
                        DataBackupView()
                    } label: {
                        SettingsRow(
                            icon: "externaldrive.fill",
                            tint: .gray,
                            title: "Backup e Exportação",
                            subtitle: "Salvar / compartilhar seus hábitos"
                        )
                    }
                } header: {
                    Text("DADOS")
                }

                // Privacidade
                Section {
                    Toggle(isOn: $analyticsEnabled) {
                        SettingsRow(
                            icon: "chart.bar.xaxis",
                            tint: .green,
                            title: "Analytics (anônimo)",
                            subtitle: "Ajuda a melhorar o app"
                        )
                    }

                    NavigationLink {
                        PrivacyView()
                    } label: {
                        SettingsRow(
                            icon: "hand.raised.fill",
                            tint: .indigo,
                            title: "Privacidade",
                            subtitle: "Permissões e dados"
                        )
                    }
                } header: {
                    Text("PRIVACIDADE")
                }

                // Suporte
                Section {
                    NavigationLink {
                        HelpView()
                    } label: {
                        SettingsRow(
                            icon: "questionmark.circle.fill",
                            tint: .mint,
                            title: "Ajuda",
                            subtitle: "Dúvidas e dicas"
                        )
                    }

                    NavigationLink {
                        FeedbackView()
                    } label: {
                        SettingsRow(
                            icon: "envelope.fill",
                            tint: .orange,
                            title: "Enviar feedback",
                            subtitle: "Sugestões e bugs"
                        )
                    }
                } header: {
                    Text("SUPORTE")
                }

                // Sobre
                Section {
                    NavigationLink {
                        AboutView()
                    } label: {
                        SettingsRow(
                            icon: "info.circle.fill",
                            tint: .secondary,
                            title: "Sobre",
                            subtitle: "Versão, termos, créditos"
                        )
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(Color.black.ignoresSafeArea())
            .navigationTitle("Ajustes")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    // MARK: - Profile Row (Card)
    private var profileRow: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.10))
                    .frame(width: 54, height: 54)

                if let profileImage {
                    profileImage
                        .resizable()
                        .scaledToFill()
                        .frame(width: 54, height: 54)
                        .clipShape(Circle())
                } else {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(Color.white.opacity(0.70))
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(displayName)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)

                Text(subtitle)
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.65))
                    .lineLimit(1)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white.opacity(0.35))
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
        .onTapGesture {
            // Futuro: abrir uma tela de "Conta" / "Perfil"
            // onde o usuário edita nome e escolhe uma foto.
        }
    }
}

// MARK: - iOS Settings-like Row

private struct SettingsRow: View {
    let icon: String
    let tint: Color
    let title: String
    let subtitle: String?

    init(icon: String, tint: Color, title: String, subtitle: String? = nil) {
        self.icon = icon
        self.tint = tint
        self.title = title
        self.subtitle = subtitle
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(tint)
                    .frame(width: 28, height: 28)
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .foregroundStyle(.white)

                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.55))
                }
            }
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Theme

enum AppTheme: String, CaseIterable, Identifiable {
    case system, dark, light

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .system: return "Sistema"
        case .dark: return "Escuro"
        case .light: return "Claro"
        }
    }
}

// MARK: - Subscreens (placeholders prontos)

private struct NotificationsSettingsView: View {
    @Binding var remindersEnabled: Bool
    @Binding var soundEnabled: Bool

    var body: some View {
        List {
            Section {
                Toggle("Ativar lembretes", isOn: $remindersEnabled)
                Toggle("Som", isOn: $soundEnabled)
            } footer: {
                Text("Você poderá adicionar múltiplos horários e visualizar todos em uma lista.")
            }

            Section {
                NavigationLink("Horários de lembrete") {
                    ReminderTimesView()
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Notificações")
    }
}

private struct ReminderTimesView: View {
    var body: some View {
        List {
            Section {
                Text("Aqui vai a lista de horários (preview), com botão “Adicionar horário”.")
                    .foregroundStyle(.secondary)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Horários")
    }
}

private struct AppearanceSettingsView: View {
    @Binding var theme: AppTheme
    @Binding var hapticsEnabled: Bool

    var body: some View {
        List {
            Section {
                Picker("Tema", selection: $theme) {
                    ForEach(AppTheme.allCases) { t in
                        Text(t.displayName).tag(t)
                    }
                }
                Toggle("Hápticos", isOn: $hapticsEnabled)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Aparência")
    }
}

private struct DataBackupView: View {
    var body: some View {
        List {
            Section {
                Text("Exportar hábitos (JSON/CSV), importar, e backup local/iCloud.")
                    .foregroundStyle(.secondary)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Backup e Exportação")
    }
}

private struct PrivacyView: View {
    var body: some View {
        List {
            Section {
                Text("Permissões (notificações), dados coletados, etc.")
                    .foregroundStyle(.secondary)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Privacidade")
    }
}

private struct HelpView: View {
    var body: some View {
        List {
            Section {
                Text("FAQ e dicas rápidas.")
                    .foregroundStyle(.secondary)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Ajuda")
    }
}

private struct FeedbackView: View {
    var body: some View {
        List {
            Section {
                Text("Enviar feedback (abre Mail / formulário).")
                    .foregroundStyle(.secondary)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Feedback")
    }
}

private struct AboutView: View {
    var body: some View {
        List {
            Section {
                HStack {
                    Text("Versão")
                    Spacer()
                    Text("1.0.0")
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Text("Build")
                    Spacer()
                    Text("1")
                        .foregroundStyle(.secondary)
                }
            }

            Section {
                Text("Termos de uso, política de privacidade, créditos.")
                    .foregroundStyle(.secondary)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Sobre")
    }
}
