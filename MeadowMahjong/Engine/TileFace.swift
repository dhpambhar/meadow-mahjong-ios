import Foundation

enum Suit: Int, CaseIterable, Codable, Sendable {
    case dots, bamboo, characters, wind, dragon, nature, season

    var rankCount: Int {
        switch self {
        case .dots, .bamboo, .characters: 9
        case .wind, .nature, .season: 4
        case .dragon: 3
        }
    }
}

/// What is printed on a tile. Two tiles match when their faces are equal.
struct TileFace: Hashable, Codable, Sendable {
    let suit: Suit
    let rank: Int   // 1-based

    /// The 42 different faces.
    static let all: [TileFace] = Suit.allCases.flatMap { suit in
        (1...suit.rankCount).map { TileFace(suit: suit, rank: $0) }
    }

    var accessibilityName: String {
        switch suit {
        case .dots: "\(rank) dots"
        case .bamboo: "\(rank) bamboo"
        case .characters: "\(rank) characters"
        case .wind: ["East", "South", "West", "North"][rank - 1] + " wind"
        case .dragon: ["Red", "Green", "White"][rank - 1] + " dragon"
        case .nature: ["Flower", "Ladybug", "Bird", "Tortoise"][rank - 1]
        case .season: ["Sun", "Rain", "Leaf", "Snow"][rank - 1]
        }
    }
}

/// A position on the board in half-tile units. A tile covers 2 × 2 units, so
/// layouts can offset rows or layers by half a tile.
struct Slot: Hashable, Codable, Sendable {
    let x: Int
    let y: Int
    let z: Int
}

struct Tile: Identifiable, Hashable, Sendable {
    let id: Int
    let slot: Slot
    var face: TileFace
}

/// SplitMix64. Seeded, so level N and day D always deal the same board.
struct SeededRandom: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}
