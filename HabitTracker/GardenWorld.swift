import SwiftUI

enum TileId: UInt8 {
    case grass = 0
    case path  = 1
    case plot  = 2

    var spriteName: String {
        switch self {
        case .grass: return "tile_grass_base"
        case .path:  return "tile_path"
        case .plot:  return "tile_plot"
        }
    }
}

struct WorldObject: Identifiable, Equatable {
    let id = UUID()
    var col: Int
    var row: Int
    var widthTiles: Int
    var heightTiles: Int
    var spriteName: String
}

struct GardenWorld {
    let cols: Int
    let rows: Int

    private(set) var tiles: [UInt8]
    private(set) var objects: [WorldObject] = []

    init(cols: Int, rows: Int, fill: TileId = .grass) {
        self.cols = cols
        self.rows = rows
        self.tiles = Array(repeating: fill.rawValue, count: cols * rows)
    }

    @inline(__always) func idx(_ c: Int, _ r: Int) -> Int { r * cols + c }

    func tile(at c: Int, _ r: Int) -> TileId {
        TileId(rawValue: tiles[idx(c, r)]) ?? .grass
    }

    mutating func setTile(_ t: TileId, at c: Int, _ r: Int) {
        guard c >= 0, c < cols, r >= 0, r < rows else { return }
        tiles[idx(c, r)] = t.rawValue
    }

    /// Mundo 500x500 com cruz de caminhos, 30 plots no centro e casa.
    static func generate500() -> GardenWorld {
        var w = GardenWorld(cols: 40, rows: 40, fill: .grass)

        let midC = w.cols / 2
        let midR = w.rows / 2

        // Caminho em cruz
        for c in 0..<w.cols { w.setTile(.path, at: c, midR) }
        for r in 0..<w.rows { w.setTile(.path, at: midC, r) }

        // Fazenda central 6x5 = 30 plots
        let farmW = 6
        let farmH = 5
        let farmLeft = midC - farmW/2
        let farmTop  = midR - farmH/2

        // Moldura (opcional, fica bonito)
        for c in (farmLeft-2)...(farmLeft+farmW+1) {
            w.setTile(.path, at: c, farmTop-2)
            w.setTile(.path, at: c, farmTop+farmH+1)
        }
        for r in (farmTop-2)...(farmTop+farmH+1) {
            w.setTile(.path, at: farmLeft-2, r)
            w.setTile(.path, at: farmLeft+farmW+1, r)
        }

        // Plots
        for r in 0..<farmH {
            for c in 0..<farmW {
                w.setTile(.plot, at: farmLeft + c, farmTop + r)
            }
        }

        // Casa (6x6 tiles). Se tileSize = 64 -> imagem 384x384.
        w.objects.append(
            WorldObject(
                col: farmLeft - 10,
                row: farmTop - 2,
                widthTiles: 6,
                heightTiles: 6,
                spriteName: "obj_house"
            )
        )

        return w
    }

    /// Centro da fazenda pra câmera iniciar.
    func farmCenterTile() -> (c: Int, r: Int) {
        (cols / 2, rows / 2)
    }
}
