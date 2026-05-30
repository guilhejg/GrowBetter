import SwiftUI

struct HTConfettiView: View {

    /// ponto de origem no coordinate space do container (o card)
    let origin: CGPoint

    @State private var pieces: [HTConfettiPiece] = []

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(pieces) { p in
                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .fill(p.color)
                        .frame(width: p.size.width, height: p.size.height)
                        .rotationEffect(.degrees(p.rotation))
                        .position(p.position)
                        .opacity(p.opacity)
                }
            }
            .onAppear {
                explode(in: geo.size)
            }
        }
    }

    private func explode(in size: CGSize) {
        let count = 80
        let palette: [Color] = [.red, .blue, .yellow, .green, .orange, .pink, .purple]

        pieces = (0..<count).map { _ in
            HTConfettiPiece(
                position: origin,
                size: CGSize(width: CGFloat.random(in: 5...10), height: CGFloat.random(in: 7...14)),
                rotation: Double.random(in: 0...360),
                color: (palette.randomElement() ?? .green).opacity(0.95),
                opacity: 1
            )
        }

        // anima a “explosão”
        for i in pieces.indices {
            let angle = Double.random(in: 0...(2 * .pi))
            let power = CGFloat.random(in: 220...520)          // força do “estouro”
            let dx = cos(angle) * power
            let dy = sin(angle) * power * 0.85                // um pouco menos pra cima/baixo

            let spin = Double.random(in: 180...520)
            let duration = Double.random(in: 0.85...1.25)

            // gravidade: depois de “subir”, cai mais um pouco
            let gravity = CGFloat.random(in: 260...520)

            DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 0...0.05)) {
                withAnimation(.easeOut(duration: duration)) {
                    // explosão
                    pieces[i].position = CGPoint(
                        x: clamp(origin.x + dx, min: -40, max: size.width + 40),
                        y: clamp(origin.y + dy, min: -40, max: size.height + 40)
                    )
                    pieces[i].rotation += spin
                }

                // queda (gravidade) + fade
                DispatchQueue.main.asyncAfter(deadline: .now() + duration * 0.55) {
                    withAnimation(.easeIn(duration: duration * 0.6)) {
                        pieces[i].position.y = clamp(pieces[i].position.y + gravity, min: -80, max: size.height + 120)
                        pieces[i].opacity = 0
                        pieces[i].rotation += spin * 0.7
                    }
                }
            }
        }
    }

    private func clamp(_ v: CGFloat, min: CGFloat, max: CGFloat) -> CGFloat {
        Swift.min(Swift.max(v, min), max)
    }
}

struct HTConfettiPiece: Identifiable {
    let id = UUID()
    var position: CGPoint
    var size: CGSize
    var rotation: Double
    var color: Color
    var opacity: Double
}
