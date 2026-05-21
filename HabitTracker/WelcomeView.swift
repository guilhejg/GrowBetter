import SwiftUI

struct WelcomeView: View {

    let onContinue: () -> Void
    let onApple: () -> Void
    let onGoogle: () -> Void

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            // ✅ degradê azul que começa embaixo e vai até o meio
            LinearGradient(
                colors: [
                    Color(red: 0.15, green: 1.0, blue: 0.20).opacity(0.65),
                    Color(red: 0.10, green: 0.95, blue: 0.35).opacity(0.55),
                    Color.clear
                ],
                startPoint: .bottom,
                endPoint: .center
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {

                Spacer(minLength: 28)

                // ✅ personagem central preenchendo bem a tela
                Image("hero_pixel")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 340)
                    .padding(.horizontal, 18)
                    .shadow(color: .black.opacity(0.35), radius: 22, x: 0, y: 14)

                Spacer(minLength: 18)

                // ✅ bloco inferior com botões (topo inferior)
                VStack(spacing: 12) {
                    Text("GrowBetter")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.bottom, 2)

                    Text("O gerenciador de hábitos que gamefica sua evolução")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.75))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 28)
                        .padding(.bottom, 10)

                    Button(action: onApple) {
                        loginButton(
                            title: "Continuar com Apple",
                            systemImage: "apple.logo",
                            fill: Color.white,
                            textColor: Color.black.opacity(0.9)
                        )
                    }
                    .buttonStyle(.plain)

                    Button(action: onGoogle) {
                        HStack(spacing: 10) {

                            Image("google_logo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 30, height: 30)

                            Text("Continuar com Google")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(Color.white.opacity(0.92))

                            Spacer()
                        }
                        .padding(.horizontal, 7)
                        .frame(height: 52)
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(Color.white.opacity(0.14))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .strokeBorder(Color.white.opacity(0.10), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)

                    Button(action: onContinue) {
                        loginButton(
                            title: "Continuar sem conta",
                            systemImage: "arrow.right",
                            fill: Color.white.opacity(0.10),
                            textColor: Color.white.opacity(0.85)
                        )
                    }
                    .buttonStyle(.plain)

                    Text("Você pode ativar login depois em Ajustes.")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.50))
                        .padding(.top, 6)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 26)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    // MARK: - UI

    private func loginButton(
        title: String,
        systemImage: String,
        fill: Color,
        textColor: Color
    ) -> some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(textColor)

            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(textColor)

            Spacer()
        }
        .padding(.horizontal, 14)
        .frame(height: 52)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(fill)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Color.white.opacity(0.10), lineWidth: 1)
        )
    }
}
