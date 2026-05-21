import SwiftUI

struct GardenMapView: View {
    let world: GardenWorld

    // 32 ou 64 (se seus tiles são 64x64 no Canva, use 64)
    let tileSize: CGFloat = 64

    @State private var scale: CGFloat = 1.15
    @State private var offset: CGSize = .zero

    @State private var lastScale: CGFloat = 1.15
    @State private var lastOffset: CGSize = .zero

    // ✅ Trava pan durante pinch
    @GestureState private var isPinching: Bool = false

    // ✅ Guarda o "ponto do conteúdo" que deve ficar fixo na tela durante o zoom
    @State private var zoomAnchorContentPoint: CGPoint? = nil

    var body: some View {
        GeometryReader { geo in
            let viewport = geo.size
            let content = CGSize(
                width: CGFloat(world.cols) * tileSize,
                height: CGFloat(world.rows) * tileSize
            )

            ZStack(alignment: .topTrailing) {
                Canvas { ctx, _ in
                    let vis = visibleTileRect(viewport: viewport, content: content, scale: scale, offset: offset)

                    // ✅ Resolve uma vez por frame
                    let grassImg = ctx.resolve(Image("tile_grass_base").interpolation(.none))
                    let pathImg  = ctx.resolve(Image("tile_path").interpolation(.none))
                    let plotImg  = ctx.resolve(Image("tile_plot").interpolation(.none))

                    for r in vis.minR...vis.maxR {
                        for c in vis.minC...vis.maxC {
                            let tile = world.tile(at: c, r)

                            let x = CGFloat(c) * tileSize
                            let y = CGFloat(r) * tileSize
                            let rect = CGRect(x: x, y: y, width: tileSize, height: tileSize)

                            switch tile {
                            case .grass: ctx.draw(grassImg, in: rect)
                            case .path:  ctx.draw(pathImg,  in: rect)
                            case .plot:  ctx.draw(plotImg,  in: rect)
                            }
                        }
                    }

                    // Objetos (casa etc.)
                    for obj in world.objects {
                        let objImg = ctx.resolve(Image(obj.spriteName).interpolation(.none))

                        let x = CGFloat(obj.col) * tileSize
                        let y = CGFloat(obj.row) * tileSize
                        let w = CGFloat(obj.widthTiles) * tileSize
                        let h = CGFloat(obj.heightTiles) * tileSize
                        let rect = CGRect(x: x, y: y, width: w, height: h)

                        ctx.draw(objImg, in: rect)
                    }
                }
                .frame(width: content.width, height: content.height)
                .scaleEffect(scale, anchor: .topLeading)
                .offset(offset)
                .gesture(panGesture(viewport: viewport, content: content))
                .simultaneousGesture(zoomGesture(viewport: viewport, content: content))
                .onAppear {
                    centerCamera(viewport: viewport, content: content, animated: false)
                }

                // Botão centralizar (opcional)
                Button {
                    centerCamera(viewport: viewport, content: content, animated: true)
                } label: {
                    Image(systemName: "scope")
                        .font(.system(size: 16, weight: .semibold))
                        .padding(12)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.top, 14)
                .padding(.trailing, 14)
            }
        }
        .ignoresSafeArea()
    }

    // MARK: - Centralizar

    private func centerCamera(viewport: CGSize, content: CGSize, animated: Bool) {
        let center = world.farmCenterTile()
        let centerPx = CGPoint(
            x: (CGFloat(center.c) + 0.5) * tileSize,
            y: (CGFloat(center.r) + 0.5) * tileSize
        )

        let desired = CGSize(
            width: viewport.width/2 - centerPx.x * scale,
            height: viewport.height/2 - centerPx.y * scale
        )

        let clamped = clampOffset(proposed: desired, viewport: viewport, content: content, scale: scale)

        if animated {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                offset = clamped
            }
        } else {
            offset = clamped
        }

        lastOffset = offset
        lastScale = scale
    }

    // MARK: - Gestos

    private func panGesture(viewport: CGSize, content: CGSize) -> some Gesture {
        DragGesture()
            .onChanged { v in
                guard !isPinching else { return } // ✅ trava pan durante pinch

                let proposed = CGSize(
                    width: lastOffset.width + v.translation.width,
                    height: lastOffset.height + v.translation.height
                )
                offset = clampOffset(proposed: proposed, viewport: viewport, content: content, scale: scale)
            }
            .onEnded { _ in
                guard !isPinching else { return }
                lastOffset = offset
            }
    }

    private func zoomGesture(viewport: CGSize, content: CGSize) -> some Gesture {
        MagnificationGesture()
            .updating($isPinching) { _, state, _ in
                state = true
            }
            .onChanged { v in
                // ✅ Ponto fixo na tela = centro do viewport
                let focalScreen = CGPoint(x: viewport.width / 2, y: viewport.height / 2)

                // ✅ No começo do pinch, calcula qual ponto do CONTEÚDO está sob esse centro
                if zoomAnchorContentPoint == nil {
                    let contentX = (focalScreen.x - offset.width) / scale
                    let contentY = (focalScreen.y - offset.height) / scale
                    zoomAnchorContentPoint = CGPoint(x: contentX, y: contentY)
                }

                let newScale = clampScale(lastScale * v)
                scale = newScale

                // ✅ Recalcula offset para manter o mesmo ponto do conteúdo no centro da tela
                if let anchor = zoomAnchorContentPoint {
                    let proposed = CGSize(
                        width: focalScreen.x - anchor.x * newScale,
                        height: focalScreen.y - anchor.y * newScale
                    )
                    offset = clampOffset(proposed: proposed, viewport: viewport, content: content, scale: newScale)
                } else {
                    offset = clampOffset(proposed: offset, viewport: viewport, content: content, scale: newScale)
                }
            }
            .onEnded { _ in
                lastScale = scale
                lastOffset = offset
                zoomAnchorContentPoint = nil // ✅ reseta para o próximo pinch
            }
    }

    // MARK: - Clamp

    private func clampScale(_ s: CGFloat) -> CGFloat {
        // Ajuste à vontade:
        min(max(s, 0.9), 2.6)
    }

    private func clampOffset(proposed: CGSize, viewport: CGSize, content: CGSize, scale: CGFloat) -> CGSize {
        let scaledW = content.width * scale
        let scaledH = content.height * scale

        let minX = viewport.width - scaledW
        let minY = viewport.height - scaledH

        let clampedX: CGFloat
        if scaledW < viewport.width {
            clampedX = (viewport.width - scaledW) / 2
        } else {
            clampedX = min(max(proposed.width, minX), 0)
        }

        let clampedY: CGFloat
        if scaledH < viewport.height {
            clampedY = (viewport.height - scaledH) / 2
        } else {
            clampedY = min(max(proposed.height, minY), 0)
        }

        return CGSize(width: clampedX, height: clampedY)
    }

    // MARK: - Visibilidade

    private func visibleTileRect(viewport: CGSize, content: CGSize, scale: CGFloat, offset: CGSize) -> (minC: Int, maxC: Int, minR: Int, maxR: Int) {
        let x0 = max(0, (-offset.width) / scale)
        let y0 = max(0, (-offset.height) / scale)
        let x1 = min(content.width, (viewport.width - offset.width) / scale)
        let y1 = min(content.height, (viewport.height - offset.height) / scale)

        let minC = Int(floor(x0 / tileSize)) - 2
        let minR = Int(floor(y0 / tileSize)) - 2
        let maxC = Int(ceil(x1 / tileSize)) + 2
        let maxR = Int(ceil(y1 / tileSize)) + 2

        return (
            minC: max(0, minC),
            maxC: min(world.cols - 1, maxC),
            minR: max(0, minR),
            maxR: min(world.rows - 1, maxR)
        )
    }
}
