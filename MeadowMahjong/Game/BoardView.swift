import SwiftUI

/// Fits a layout into the space available and places each slot.
struct BoardMetrics {
    static let aspect: CGFloat = 1.3          // tile height / width
    static let layerShift: CGFloat = 0.11     // each layer moves up-left by this much of a tile width

    let tileSize: CGSize
    private let origin: CGPoint
    private let minX: Int
    private let minY: Int
    private let shift: CGFloat

    init(slots: [Slot], in size: CGSize) {
        minX = slots.map(\.x).min() ?? 0
        minY = slots.map(\.y).min() ?? 0
        let cols = CGFloat((slots.map(\.x).max() ?? 0) - minX + 2) / 2
        let rows = CGFloat((slots.map(\.y).max() ?? 0) - minY + 2) / 2
        let layers = CGFloat(slots.map(\.z).max() ?? 0)
        let byWidth = size.width / (cols + layers * Self.layerShift)
        let byHeight = size.height / (rows * Self.aspect + layers * Self.layerShift)
        let w = max(12, min(byWidth, byHeight, 130))   // 130 pt caps the small boards on iPad
        tileSize = CGSize(width: w, height: w * Self.aspect)
        shift = w * Self.layerShift
        let boardW = cols * w + layers * shift
        let boardH = rows * w * Self.aspect + layers * shift
        origin = CGPoint(x: (size.width - boardW) / 2 + layers * shift, y: (size.height - boardH) / 2 + layers * shift)
    }

    func center(of slot: Slot) -> CGPoint {
        CGPoint(x: origin.x + CGFloat(slot.x - minX) * tileSize.width / 2 + tileSize.width / 2 - CGFloat(slot.z) * shift,
                y: origin.y + CGFloat(slot.y - minY) * tileSize.height / 2 + tileSize.height / 2 - CGFloat(slot.z) * shift)
    }

    /// Higher layers on top, then lower rows, then further right, so each tile's thickness is covered correctly.
    func zIndex(of slot: Slot) -> Double {
        Double(slot.z * 100_000 + (slot.y - minY) * 200 + (slot.x - minX))
    }
}

struct BoardView: View {
    let model: GameModel
    let dimBlocked: Bool

    var body: some View {
        GeometryReader { geo in
            let metrics = BoardMetrics(slots: model.board.tiles.map(\.slot), in: geo.size)
            ZStack(alignment: .topLeading) {
                ForEach(model.board.remainingTiles) { tile in
                    tileView(tile, metrics: metrics)
                }
                ForEach(model.flights) { flight in
                    FlightView(flight: flight, metrics: metrics)
                        .zIndex(1_000_000)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .animation(.spring(response: 0.25, dampingFraction: 0.55), value: model.selected)
            .animation(.easeInOut(duration: 0.55), value: model.shuffles)
            .animation(.spring(response: 0.35, dampingFraction: 0.7), value: model.board.remainingCount)
        }
    }

    private func tileView(_ tile: Tile, metrics: BoardMetrics) -> some View {
        let isSelected = model.selected == tile.id
        let shakes = model.shakes[tile.id, default: 0]
        return TileView(face: tile.face,
                        size: metrics.tileSize,
                        isSelected: isSelected,
                        isHinted: model.hinted.contains(tile.id),
                        isDimmed: dimBlocked && !model.board.isFree(tile.id))
            .scaleEffect(isSelected ? 1.07 : 1)
            .offset(y: isSelected ? -metrics.tileSize.width * 0.08 : 0)
            .rotation3DEffect(.degrees(Double(model.shuffles) * 360), axis: (x: 0, y: 1, z: 0), perspective: 0.4)
            .modifier(ShakeEffect(shakes: CGFloat(shakes)))
            .animation(.linear(duration: 0.4), value: shakes)
            .contentShape(Rectangle())
            .onTapGesture { model.tap(tile.id) }
            .position(metrics.center(of: tile.slot))
            .zIndex(metrics.zIndex(of: tile.slot) + (isSelected ? 50_000 : 0))
            .transition(.identity)      // the pair's FlightView does the exit
    }
}

/// Side-to-side wobble for a tap on a blocked tile. Animate `shakes` up by one per wobble.
struct ShakeEffect: GeometryEffect {
    var shakes: CGFloat
    var animatableData: CGFloat {
        get { shakes }
        set { shakes = newValue }
    }

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX: 7 * sin(shakes * .pi * 4), y: 0))
    }
}

/// A matched pair: both tiles glide together, kiss, then pop in a burst of sparkles and leaves.
struct FlightView: View {
    let flight: GameModel.Flight
    let metrics: BoardMetrics

    @State private var met = false
    @State private var popped = false

    var body: some View {
        let pa = metrics.center(of: flight.a.slot)
        let pb = metrics.center(of: flight.b.slot)
        let leftFirst = pa.x <= pb.x
        let mid = CGPoint(x: (pa.x + pb.x) / 2, y: min(pa.y, pb.y) - metrics.tileSize.height * 0.2)
        let half = metrics.tileSize.width * 0.48
        let aTarget = CGPoint(x: mid.x + (leftFirst ? -half : half), y: mid.y)
        let bTarget = CGPoint(x: mid.x + (leftFirst ? half : -half), y: mid.y)

        ZStack {
            flying(flight.a, from: pa, to: aTarget)
            flying(flight.b, from: pb, to: bTarget)
            if popped {
                SparkleBurst(intensity: flight.combo)
                    .position(mid)
            }
        }
        .allowsHitTesting(false)
        .onAppear {
            withAnimation(.easeIn(duration: 0.22)) {
                met = true
            } completion: {
                withAnimation(.easeOut(duration: 0.28)) { popped = true }
            }
        }
    }

    private func flying(_ tile: Tile, from: CGPoint, to: CGPoint) -> some View {
        TileView(face: tile.face, size: metrics.tileSize, isSelected: true)
            .scaleEffect(popped ? 1.35 : (met ? 1.1 : 1))
            .opacity(popped ? 0 : 1)
            .position(met ? to : from)
    }
}
