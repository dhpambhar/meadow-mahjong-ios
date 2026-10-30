import Foundation

/// Where the tiles go, before any faces are dealt.
struct Layout: Sendable {
    let name: String
    let slots: [Slot]

    /// Removes duplicates, sorts bottom layer first, and drops the highest tile
    /// when the count is odd, so every layout deals whole pairs.
    init(name: String, slots: [Slot]) {
        var seen = Set<Slot>()
        var unique = slots.filter { seen.insert($0).inserted }
        unique.sort { ($0.z, $0.y, $0.x) < ($1.z, $1.y, $1.x) }
        if unique.count % 2 == 1 { unique.removeLast() }
        self.name = name
        self.slots = unique
    }
}

/// Collects slots for a layout. Coordinates are in half-tile units.
private struct Builder {
    var slots: [Slot] = []

    /// `cols` × `rows` tiles side by side, top-left tile at (x, y).
    mutating func grid(x: Int, y: Int, cols: Int, rows: Int, z: Int) {
        for r in 0..<rows {
            for c in 0..<cols { slots.append(Slot(x: x + 2 * c, y: y + 2 * r, z: z)) }
        }
    }

    /// One row per width, each centred on `centerX`, starting at row `y`.
    mutating func rows(_ widths: [Int], centerX: Int, y: Int, z: Int) {
        for (r, width) in widths.enumerated() {
            grid(x: centerX - width, y: y + 2 * r, cols: width, rows: 1, z: z)
        }
    }

    mutating func tile(_ x: Int, _ y: Int, _ z: Int) {
        slots.append(Slot(x: x, y: y, z: z))
    }

    func layout(_ name: String) -> Layout { Layout(name: name, slots: slots) }
}

/// The handcrafted layouts, sized for a portrait phone: at most 8 tiles wide.
enum Layouts {
    static let seedling: Layout = {
        var b = Builder()
        b.grid(x: 0, y: 0, cols: 4, rows: 4, z: 0)
        b.grid(x: 2, y: 2, cols: 2, rows: 2, z: 1)
        return b.layout("Seedling")
    }()

    static let lotus: Layout = {
        var b = Builder()
        b.grid(x: 0, y: 0, cols: 4, rows: 4, z: 0)
        b.grid(x: 2, y: -2, cols: 2, rows: 1, z: 0)
        b.grid(x: 2, y: 8, cols: 2, rows: 1, z: 0)
        b.grid(x: -2, y: 2, cols: 1, rows: 2, z: 0)
        b.grid(x: 8, y: 2, cols: 1, rows: 2, z: 0)
        b.grid(x: 2, y: 2, cols: 2, rows: 2, z: 1)
        b.tile(3, 3, 2)
        return b.layout("Lotus")
    }()

    static let clover: Layout = {
        var b = Builder()
        b.rows([3, 5, 5, 5, 3], centerX: 5, y: 0, z: 0)
        b.rows([3, 3, 3], centerX: 5, y: 2, z: 1)
        b.tile(4, 4, 2)
        return b.layout("Clover")
    }()

    static let sunflower: Layout = {
        var b = Builder()
        b.rows([2, 4, 6, 6, 4, 2], centerX: 6, y: 0, z: 0)
        b.rows([2, 4, 4, 2], centerX: 6, y: 2, z: 1)
        b.rows([2, 2], centerX: 6, y: 4, z: 2)
        return b.layout("Sunflower")
    }()

    static let butterfly: Layout = {
        var b = Builder()
        b.grid(x: 0, y: 0, cols: 3, rows: 4, z: 0)
        b.grid(x: 10, y: 0, cols: 3, rows: 4, z: 0)
        b.grid(x: 7, y: -1, cols: 1, rows: 5, z: 0)
        b.grid(x: 1, y: 1, cols: 2, rows: 3, z: 1)
        b.grid(x: 11, y: 1, cols: 2, rows: 3, z: 1)
        b.grid(x: 7, y: 1, cols: 1, rows: 3, z: 1)
        b.tile(7, 3, 2)
        return b.layout("Butterfly")
    }()

    static let river: Layout = {
        var b = Builder()
        for r in 0..<8 { b.grid(x: r, y: 2 * r, cols: 4, rows: 1, z: 0) }
        for r in 1..<7 { b.grid(x: r + 1, y: 2 * r, cols: 3, rows: 1, z: 1) }
        return b.layout("River")
    }()

    static let pyramid: Layout = {
        var b = Builder()
        b.grid(x: 0, y: 0, cols: 6, rows: 6, z: 0)
        b.grid(x: 2, y: 2, cols: 4, rows: 4, z: 1)
        b.grid(x: 4, y: 4, cols: 2, rows: 2, z: 2)
        b.tile(5, 5, 3)
        return b.layout("Pyramid")
    }()

    static let twinPeaks: Layout = {
        var b = Builder()
        for top in [0, 10] {
            b.grid(x: 0, y: top, cols: 4, rows: 4, z: 0)
            b.grid(x: 2, y: top + 2, cols: 2, rows: 2, z: 1)
            b.tile(3, top + 3, 2)
        }
        b.grid(x: 2, y: 8, cols: 2, rows: 1, z: 0)
        return b.layout("Twin Peaks")
    }()

    static let lantern: Layout = {
        var b = Builder()
        b.rows([2, 4, 6, 6, 6, 6, 4, 2], centerX: 6, y: 0, z: 0)
        b.rows([2, 4, 4, 4, 4, 2], centerX: 6, y: 2, z: 1)
        b.rows([2, 2, 2, 2], centerX: 6, y: 4, z: 2)
        b.rows([2], centerX: 6, y: 7, z: 3)
        return b.layout("Lantern")
    }()

    static let fortress: Layout = {
        var b = Builder()
        b.grid(x: 0, y: 0, cols: 8, rows: 6, z: 0)
        b.grid(x: 2, y: 2, cols: 6, rows: 4, z: 1)
        b.grid(x: 4, y: 4, cols: 4, rows: 2, z: 2)
        b.grid(x: 6, y: 5, cols: 2, rows: 1, z: 3)
        return b.layout("Fortress")
    }()

    static let terraces: Layout = {
        var b = Builder()
        b.grid(x: 0, y: 0, cols: 6, rows: 8, z: 0)
        b.grid(x: 1, y: 1, cols: 5, rows: 7, z: 1)
        b.grid(x: 2, y: 2, cols: 4, rows: 6, z: 2)
        b.grid(x: 3, y: 3, cols: 3, rows: 5, z: 3)
        return b.layout("Terraces")
    }()

    static let oldOak: Layout = {
        var b = Builder()
        b.grid(x: 0, y: 0, cols: 8, rows: 9, z: 0)
        b.grid(x: 1, y: 1, cols: 7, rows: 8, z: 1)
        b.grid(x: 4, y: 5, cols: 4, rows: 4, z: 2)
        return b.layout("Old Oak")
    }()

    /// Levels 1 to 12 play these in order. Later levels pick from index 3 on.
    static let progression: [Layout] = [
        seedling, lotus, clover, sunflower, butterfly, twinPeaks,
        river, pyramid, lantern, fortress, terraces, oldOak,
    ]

    static let daily: [Layout] = [pyramid, twinPeaks, lantern, fortress, terraces, oldOak]
}

/// A calendar day, used as the Daily Challenge's seed and storage key.
struct DayKey: Hashable, Comparable, Codable, Sendable {
    let year: Int
    let month: Int
    let day: Int

    init(year: Int, month: Int, day: Int) {
        self.year = year
        self.month = month
        self.day = day
    }

    init(_ date: Date, calendar: Calendar = .current) {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        self.init(year: parts.year ?? 2026, month: parts.month ?? 1, day: parts.day ?? 1)
    }

    static var today: DayKey { DayKey(Date()) }

    var string: String { String(format: "%04d-%02d-%02d", year, month, day) }
    var number: Int { year * 10_000 + month * 100 + day }

    func date(calendar: Calendar = .current) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day)) ?? Date()
    }

    static func < (lhs: DayKey, rhs: DayKey) -> Bool { lhs.number < rhs.number }
}

/// What to play: a level or a day. Everything about the deal follows from it.
struct GameConfig: Hashable, Sendable {
    enum Kind: Hashable, Sendable {
        case level(Int)
        case daily(DayKey)
    }

    let kind: Kind

    static func level(_ n: Int) -> GameConfig { GameConfig(kind: .level(max(1, n))) }
    static func daily(_ day: DayKey) -> GameConfig { GameConfig(kind: .daily(day)) }

    var layout: Layout {
        switch kind {
        case .level(let n):
            if n <= Layouts.progression.count { return Layouts.progression[n - 1] }
            var rng = SeededRandom(seed: UInt64(n) &* 7919)
            return Layouts.progression[Int.random(in: 3..<Layouts.progression.count, using: &rng)]
        case .daily(let day):
            var rng = SeededRandom(seed: UInt64(day.number) &* 104_729)
            return Layouts.daily[Int.random(in: 0..<Layouts.daily.count, using: &rng)]
        }
    }

    /// How many different faces the deal uses. Fewer is easier to scan.
    var variety: Int {
        switch kind {
        case .level(let n): min(TileFace.all.count, 4 + n)
        case .daily: 30
        }
    }

    private var seed: UInt64 {
        switch kind {
        case .level(let n): UInt64(n) &* 1_000_003
        case .daily(let day): UInt64(day.number) &* 31
        }
    }

    var title: String {
        switch kind {
        case .level(let n): "Level \(n)"
        case .daily(let day): day.date().formatted(.dateTime.month(.abbreviated).day())
        }
    }

    var isDaily: Bool {
        if case .daily = kind { return true }
        return false
    }

    /// The same board every time for the same config, so Restart replays the puzzle.
    func makeBoard() -> Board {
        let layout = layout
        var rng = SeededRandom(seed: seed)
        let pairCount = layout.slots.count / 2
        let kinds = Array(TileFace.all.shuffled(using: &rng).prefix(min(variety, pairCount)))
        let pairs = (0..<pairCount).map { kinds[$0 % kinds.count] }
        var board = Board(layout: layout)
        if !board.deal(pairs: pairs, using: &rng) {
            // Not seen with the shipped layouts. Retry longer, still seeded so Restart matches.
            var fallback = SeededRandom(seed: seed &+ 1)
            board.deal(pairs: pairs, using: &fallback, attempts: 400)
        }
        return board
    }
}
