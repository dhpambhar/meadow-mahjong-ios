import Foundation

/// The tiles of one game and which are still on the table.
///
/// Free rule: nothing on a higher layer overlaps the tile, and its left or its
/// right side is open on its own layer.
struct Board: Sendable {
    struct Pair: Hashable, Sendable {
        let a: Int
        let b: Int
    }

    private(set) var tiles: [Tile]
    private(set) var present: [Bool]
    /// The removal order the last deal was built from. Playing it clears the board.
    private(set) var solution: [Pair] = []

    private let above: [[Int]]
    private let left: [[Int]]
    private let right: [[Int]]

    /// All tiles present, every face a placeholder. Call `deal` next.
    init(layout: Layout) {
        let slots = layout.slots
        var above = [[Int]](repeating: [], count: slots.count)
        var left = above
        var right = above
        for i in slots.indices {
            let s = slots[i]
            for j in slots.indices where j != i {
                let o = slots[j]
                let dx = o.x - s.x
                let dy = o.y - s.y
                guard abs(dy) < 2 else { continue }
                if o.z > s.z, abs(dx) < 2 {
                    above[i].append(j)
                } else if o.z == s.z {
                    if dx == -2 { left[i].append(j) }
                    if dx == 2 { right[i].append(j) }
                }
            }
        }
        self.above = above
        self.left = left
        self.right = right
        tiles = slots.enumerated().map { Tile(id: $0.offset, slot: $0.element, face: TileFace(suit: .dots, rank: 1)) }
        present = Array(repeating: true, count: slots.count)
    }

    // MARK: - Reading

    var remainingCount: Int { present.reduce(0) { $1 ? $0 + 1 : $0 } }
    var remainingTiles: [Tile] { tiles.filter { present[$0.id] } }
    var isCleared: Bool { !present.contains(true) }

    func isPresent(_ id: Int) -> Bool { present[id] }
    func face(of id: Int) -> TileFace { tiles[id].face }
    func isFree(_ id: Int) -> Bool { isFree(id, in: present) }

    func canMatch(_ a: Int, _ b: Int) -> Bool {
        a != b && present[a] && present[b] && tiles[a].face == tiles[b].face && isFree(a) && isFree(b)
    }

    /// Two free tiles with the same face, or nil when the player is stuck.
    func matchablePair() -> Pair? {
        var firstByFace: [TileFace: Int] = [:]
        for tile in tiles where present[tile.id] && isFree(tile.id) {
            if let other = firstByFace[tile.face] { return Pair(a: other, b: tile.id) }
            firstByFace[tile.face] = tile.id
        }
        return nil
    }

    private func isFree(_ id: Int, in mask: [Bool]) -> Bool {
        guard mask[id], !above[id].contains(where: { mask[$0] }) else { return false }
        return !left[id].contains(where: { mask[$0] }) || !right[id].contains(where: { mask[$0] })
    }

    // MARK: - Playing

    mutating func remove(_ pair: Pair) {
        present[pair.a] = false
        present[pair.b] = false
    }

    mutating func restore(_ pair: Pair) {
        present[pair.a] = true
        present[pair.b] = true
    }

    // MARK: - Dealing

    /// Gives the tiles on the table the faces in `faces` (one entry per pair) so
    /// that they can all be cleared.
    ///
    /// Works by playing a game: take two random free tiles, give both the same
    /// face, lift them off, repeat. That order is a real solution. A run that
    /// gets stuck (fewer than two free tiles) is thrown away and retried.
    @discardableResult
    mutating func deal(pairs faces: [TileFace], using rng: inout some RandomNumberGenerator, attempts: Int = 80) -> Bool {
        let ids = tiles.indices.filter { present[$0] }
        guard faces.count * 2 == ids.count else { return false }

        for _ in 0..<attempts {
            var mask = present
            var order: [Pair] = []
            var stuck = false
            for _ in faces {
                var free = ids.filter { isFree($0, in: mask) }
                guard free.count >= 2 else { stuck = true; break }
                free.shuffle(using: &rng)
                mask[free[0]] = false
                mask[free[1]] = false
                order.append(Pair(a: free[0], b: free[1]))
            }
            if stuck { continue }

            for (pair, face) in zip(order, faces.shuffled(using: &rng)) {
                tiles[pair.a].face = face
                tiles[pair.b].face = face
            }
            solution = order
            return true
        }
        return false
    }

    /// Re-deals the faces still on the table so the rest can be cleared.
    /// Returns false when no clearable arrangement was found.
    mutating func reshuffle(using rng: inout some RandomNumberGenerator) -> Bool {
        var counts: [TileFace: Int] = [:]
        for tile in remainingTiles { counts[tile.face, default: 0] += 1 }
        let pairs = TileFace.all.flatMap { face in Array(repeating: face, count: counts[face, default: 0] / 2) }
        return deal(pairs: pairs, using: &rng)
    }
}
