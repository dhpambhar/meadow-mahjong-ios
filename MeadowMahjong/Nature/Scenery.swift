import SwiftUI

/// The background scenes. Each unlocks at a level and has its own palette and creatures.
enum Scenery: String, CaseIterable, Identifiable, Sendable {
    case meadow, forest, sunset, blossom, autumn, night

    var id: String { rawValue }

    var title: String {
        switch self {
        case .meadow: "Spring Meadow"
        case .forest: "Misty Forest"
        case .sunset: "Sunset Lake"
        case .blossom: "Cherry Blossom"
        case .autumn: "Autumn Hills"
        case .night: "Firefly Night"
        }
    }

    var symbol: String {
        switch self {
        case .meadow: "camera.macro"
        case .forest: "tree.fill"
        case .sunset: "sun.horizon.fill"
        case .blossom: "leaf.fill"
        case .autumn: "wind"
        case .night: "moon.stars.fill"
        }
    }

    var unlockLevel: Int {
        switch self {
        case .meadow: 1
        case .forest: 4
        case .sunset: 8
        case .blossom: 12
        case .autumn: 18
        case .night: 25
        }
    }

    func isUnlocked(atLevel level: Int) -> Bool { level >= unlockLevel }

    var palette: ScenePalette {
        switch self {
        case .meadow:
            ScenePalette(sky: [0x5DB8F5, 0xA9DDFB, 0xE6F7FF], sun: 0xFFF1A8, sunAt: CGPoint(x: 0.8, y: 0.12),
                         hills: [0x9FD98A, 0x6CC05C, 0x3E9B47], grass: 0x2F7D3A, cloud: 0xFFFFFF,
                         particles: [0xFFFFFF, 0xFFD6E8, 0xFFF3A6], particle: .petal, particleCount: 18,
                         trees: .round(0x4C9F4A), flowers: [0xFF6F91, 0xFFD43B, 0xFFFFFF, 0xB197FC],
                         butterflies: 3, birds: 3)
        case .forest:
            ScenePalette(sky: [0x7DB89B, 0xBFDDC5, 0xEAF5E1], sun: 0xFFF7D1, sunAt: CGPoint(x: 0.25, y: 0.1),
                         hills: [0x6FA580, 0x467F59, 0x2B5E3F], grass: 0x22502F, cloud: 0xF4FBF2,
                         particles: [0x7CB342, 0xAED581, 0x558B2F, 0xC5E1A5], particle: .leaf, particleCount: 16,
                         trees: .pine(0x1F4A33), beams: true, mist: true, fireflies: 8)
        case .sunset:
            ScenePalette(sky: [0x3B3F8C, 0xC75D93, 0xFFB36B], sun: 0xFFE29A, sunAt: CGPoint(x: 0.72, y: 0.17), sunScale: 1.5,
                         hills: [0x8E5A8C, 0x5E3F73, 0x3B2B55], grass: 0x2B1F40, cloud: 0xFFC7B0,
                         particles: [0xFFD27F, 0xFFB38A], particle: .sparkle, particleCount: 14,
                         trees: .pine(0x2A1E3F), water: true, birds: 5)
        case .blossom:
            ScenePalette(sky: [0xFFC6DD, 0xFFE3EE, 0xFFF6FA], sun: 0xFFF5E1, sunAt: CGPoint(x: 0.78, y: 0.14),
                         hills: [0xBDE3A8, 0x8FCC7E, 0x5FA866], grass: 0x3F8A4A, cloud: 0xFFFFFF,
                         particles: [0xFFB7CE, 0xFFC9DA, 0xFF9EBB, 0xFFFFFF], particle: .petal, particleCount: 34,
                         trees: .round(0xFFA6C4), flowers: [0xFF8FB1, 0xFFFFFF], butterflies: 2)
        case .autumn:
            ScenePalette(sky: [0xF7A35C, 0xFFD39A, 0xFFF0D6], sun: 0xFFF0C2, sunAt: CGPoint(x: 0.2, y: 0.16),
                         hills: [0xD9924F, 0xB5622F, 0x7E3F1F], grass: 0x5E2E17, cloud: 0xFFF3E0,
                         particles: [0xE2711D, 0xFFB627, 0xCC3F0C, 0xA33B20], particle: .leaf, particleCount: 24,
                         trees: .round(0xE07A2E), birds: 4)
        case .night:
            ScenePalette(sky: [0x0B1340, 0x23306B, 0x3E4A8A], sun: 0xF5F3CE, sunAt: CGPoint(x: 0.78, y: 0.13), isNight: true,
                         hills: [0x25335E, 0x1B2648, 0x121A33], grass: 0x0D1428, cloud: 0x4A5694,
                         particles: [], particle: .petal, particleCount: 0,
                         trees: .pine(0x0E1630), stars: true, fireflies: 26)
        }
    }
}

struct ScenePalette {
    enum Particle { case petal, leaf, sparkle }
    enum Trees {
        case pine(UInt32)
        case round(UInt32)
    }

    var sky: [UInt32]
    var sun: UInt32
    var sunAt: CGPoint
    var sunScale: CGFloat = 1
    var isNight = false
    var hills: [UInt32]          // back to front
    var grass: UInt32
    var cloud: UInt32
    var particles: [UInt32]
    var particle: Particle
    var particleCount: Int
    var trees: Trees? = nil
    var flowers: [UInt32] = []
    var beams = false
    var mist = false
    var water = false
    var stars = false
    var butterflies = 0
    var birds = 0
    var fireflies = 0
}
