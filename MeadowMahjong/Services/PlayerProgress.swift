import Foundation
import Observation

/// Level, stars, solved days and settings, kept in UserDefaults.
@MainActor
@Observable
final class PlayerProgress {
    private enum Key {
        static let level = "level"
        static let stars = "stars"
        static let solvedDays = "solvedDays"
        static let sound = "soundOn"
        static let haptics = "hapticsOn"
        static let dimBlocked = "dimBlocked"
        static let scenery = "scenery"
    }

    @ObservationIgnored private let defaults: UserDefaults

    /// The next level to play.
    private(set) var level: Int { didSet { defaults.set(level, forKey: Key.level) } }
    /// Best stars per level, keyed by level number.
    private(set) var stars: [Int: Int] {
        didSet { defaults.set(Dictionary(uniqueKeysWithValues: stars.map { (String($0.key), $0.value) }), forKey: Key.stars) }
    }
    private(set) var solvedDays: Set<String> { didSet { defaults.set(Array(solvedDays), forKey: Key.solvedDays) } }

    var soundOn: Bool { didSet { defaults.set(soundOn, forKey: Key.sound) } }
    var hapticsOn: Bool { didSet { defaults.set(hapticsOn, forKey: Key.haptics) } }
    var dimBlocked: Bool { didSet { defaults.set(dimBlocked, forKey: Key.dimBlocked) } }
    var scenery: Scenery { didSet { defaults.set(scenery.rawValue, forKey: Key.scenery) } }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        level = max(1, defaults.integer(forKey: Key.level))
        let stored = defaults.dictionary(forKey: Key.stars) as? [String: Int] ?? [:]
        stars = Dictionary(uniqueKeysWithValues: stored.compactMap { key, value in Int(key).map { ($0, value) } })
        solvedDays = Set(defaults.stringArray(forKey: Key.solvedDays) ?? [])
        soundOn = defaults.object(forKey: Key.sound) as? Bool ?? true
        hapticsOn = defaults.object(forKey: Key.haptics) as? Bool ?? true
        dimBlocked = defaults.object(forKey: Key.dimBlocked) as? Bool ?? true
        scenery = Scenery(rawValue: defaults.string(forKey: Key.scenery) ?? "") ?? .meadow
    }

    var totalStars: Int { stars.values.reduce(0, +) }

    func isSolved(_ day: DayKey) -> Bool { solvedDays.contains(day.string) }

    func trophies(inYear year: Int, month: Int) -> Int {
        let prefix = String(format: "%04d-%02d-", year, month)
        return solvedDays.filter { $0.hasPrefix(prefix) }.count
    }

    /// Saves a win. Returns the scene this win unlocked, if any, and switches to it.
    @discardableResult
    func recordWin(_ config: GameConfig, stars earned: Int) -> Scenery? {
        switch config.kind {
        case .level(let n):
            stars[n] = max(stars[n] ?? 0, earned)
            guard n >= level else { return nil }
            level = n + 1
            if let unlocked = Scenery.allCases.first(where: { $0.unlockLevel == level }) {
                scenery = unlocked
                return unlocked
            }
            return nil
        case .daily(let day):
            solvedDays.insert(day.string)
            return nil
        }
    }
}
