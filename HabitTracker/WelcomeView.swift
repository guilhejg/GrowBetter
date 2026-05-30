import SwiftUI

struct WelcomeView: View {

    let onContinue: () -> Void
    let onApple: () -> Void
    let onGoogle: () -> Void

    @State private var step: WelcomeStep = .intro
    @State private var guestName = ""

    var body: some View {
        ZStack {
            HTAppBackground()

            switch step {
            case .intro:
                introScreen
            case .newUser:
                newUserScreen
            case .guestName:
                guestNameScreen
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .animation(.easeInOut(duration: 0.22), value: step)
    }

    private var introScreen: some View {
        VStack(spacing: 0) {
            Spacer()

            mascotTitle("Bem vindo,\npequeno padawa")
                .padding(.bottom, 138)

            VStack(spacing: 12) {
                welcomeButton("Eu não te conheço") {
                    step = .newUser
                }

                welcomeButton("Eu já te conheço") {
                    HTAccountSession.saveLocalSession(name: "Convidado")
                    onApple()
                }
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 42)
        }
        .transition(.opacity)
    }

    private var newUserScreen: some View {
        VStack(spacing: 0) {
            Spacer()

            mascotTitle("Vamos lá,\nquem é você?")
                .padding(.bottom, 138)

            VStack(spacing: 12) {
                welcomeButton("Cadastrar com sua conta Apple") {
                    step = .guestName
                }

                welcomeButton("Entrar como convidado") {
                    step = .guestName
                }
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 42)
        }
        .transition(.opacity)
    }

    private var guestNameScreen: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 18) {
                Image("agagblom_main")
                    .resizable()
                    .interpolation(.none)
                    .scaledToFit()
                    .frame(width: 150, height: 150)
                    .shadow(color: .black.opacity(0.26), radius: 16, x: 0, y: 10)

                Text("Qual o seu\nnome?")
                    .font(.system(size: 24, weight: .heavy))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .lineSpacing(-3)
                    .minimumScaleFactor(0.82)

                guestNameField
                    .padding(.top, 20)
            }
            .padding(.bottom, 300)

            welcomeButton("Entrar como convidado") {
                HTAccountSession.saveGuestName(guestName)
                onContinue()
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 42)
        }
        .transition(.opacity)
    }

    private func mascotTitle(_ title: String) -> some View {
        VStack(spacing: 18) {
            Image("agagblom_main")
                .resizable()
                .interpolation(.none)
                .scaledToFit()
                .frame(width: 150, height: 150)
                .shadow(color: .black.opacity(0.26), radius: 16, x: 0, y: 10)

            Text(title)
                .font(.system(size: 24, weight: .heavy))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .lineSpacing(-3)
                .minimumScaleFactor(0.82)
        }
    }

    private var guestNameField: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color(red: 0.09, green: 0.66, blue: 0.06))

            if guestName.isEmpty {
                Text("Seu nome")
                    .font(.system(size: 18, weight: .heavy))
                    .foregroundStyle(Color.black.opacity(0.30))
                    .padding(.horizontal, 16)
            }

            TextField("", text: $guestName)
                .font(.system(size: 18, weight: .heavy))
                .foregroundStyle(.white)
                .tint(.white)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .padding(.horizontal, 16)
        }
        .frame(height: 47)
        .padding(.horizontal, 40)
    }

    private func welcomeButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 18, weight: .heavy))
                .foregroundStyle(Color.black.opacity(0.92))
                .lineLimit(1)
                .minimumScaleFactor(0.84)
                .frame(maxWidth: .infinity)
                .frame(height: 47)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color(red: 0.66, green: 0.96, blue: 0.11))
                )
        }
        .buttonStyle(.plain)
    }
}

private enum WelcomeStep: Equatable {
    case intro
    case newUser
    case guestName
}
