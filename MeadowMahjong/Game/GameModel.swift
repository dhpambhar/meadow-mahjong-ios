import Foundation
import Observation

/// One game in progress: taps, matches, combo and praise, help tools, win and stuck states.
@MainActor
@Observable
final class GameModel {
    enum Phase: Equatable { case playing, stuck, won }

    /// A matched pair on its way off the board. Drawn by `FlightView`, removed after the animation.
    struct Flight: Identifiable {
        let id = UUID()
        let a: Tile
        let b: Tile
        let combo: Int
    }

    struct Praise: Identifiable, Equatable {
        let id = UUID()
        let text: String
        let tier: Int

        /// The word for a combo, or nil for a single match.
        static func text(forCombo combo: Int) -> String? {
            switch combo {
            case ..<2: nil
            case 2: "Good!"
            case 3: "Great!"
            case 4: "Excellent!"
            case 5: "Amazing!"
            case 6: "Fantastic!"
            default: "Unbelievable!"
            }
        }
    }

    private struct Move {
        let pair: Board.Pair
        let points: Int
    }

    /// Matches closer together than this keep the combo going.
    static let comboWindow: TimeInterval = 4

    let config: GameConfig
    private(set) var board: Board
    private(set) var phase: Phase = .playing
    private(set) var selected: Int?
    private(set) var hinted: Set<Int> = []
    private(set) var shakes: [Int: Int] = [:]
    private(set) var shuffles = 0          // drives the flip animation
    private(set) var flights: [Flight] = []
    private(set) var praise: Praise?

    private(set) var combo = 0
    private(set) var lastMatchAt: Date?
    private(set) var bestCombo = 0
    private(set) var score = 0
    private(set) var hintsUsed = 0
    private(set) var shufflesUsed = 0
    private(set) var shuffleFailed = false
    private(set) var startedAt = Date()
    private(set) var finishedAt: Date?

    @ObservationIgnored private var history: [Move] = []
    @ObservationIgnored private var praisedHalfway = false
    @ObservationIgnored private let feedback: Feedback?

    init(config: GameConfig, feedback: Feedback?) {
        self.config = config
        self.feedback = feedback
        board = config.makeBoard()
    }

    var canUndo: Bool { !history.isEmpty && finishedAt == nil }
    var tilesLeft: Int { board.remainingCount }

    /// 3 stars without help, 2 with a little, 1 otherwise. Undo is free.
    var stars: Int {
        switch hintsUsed + shufflesUsed {
        case 0: 3
        case 1...2: 2
        default: 1
        }
    }

    var elapsed: TimeInterval { (finishedAt ?? Date()).timeIntervalSince(startedAt) }

    // MARK: - Taps

    func tap(_ id: Int) {
        guard phase == .playing, board.isPresent(id) else { return }
        guard board.isFree(id) else {
            shakes[id, default: 0] += 1
            feedback?.blocked()
            return
        }
        hinted = []
        guard let first = selected else {
            selected = id
            feedback?.select()
            return
        }
        if first == id {
            selected = nil
        } else if board.canMatch(first, id) {
            match(Board.Pair(a: first, b: id))
        } else {
            selected = id
            feedback?.select()
        }
    }

    private func match(_ pair: Board.Pair) {
        let now = Date()
        if let last = lastMatchAt, now.timeIntervalSince(last) <= Self.comboWindow {
            combo += 1
        } else {
            combo = 1
        }
        lastMatchAt = now
        bestCombo = max(bestCombo, combo)
        let points = 10 * combo
        score += points

        let flight = Flight(a: board.tiles[pair.a], b: board.tiles[pair.b], combo: combo)
        flights.append(flight)
        board.remove(pair)
        history.append(Move(pair: pair, points: points))
        selected = nil
        feedback?.match(combo: combo)
        removeFlight(flight.id, after: 0.8)

        if board.isCleared {
            win()
            return
        }
        if let text = Praise.text(forCombo: combo) {
            show(Praise(text: text, tier: combo))
        } else if !praisedHalfway, board.remainingCount * 2 <= board.tiles.count {
            praisedHalfway = true
            show(Praise(text: "Halfway there!", tier: 1))
        }
        if board.matchablePair() == nil {
            phase = .stuck
            shuffleFailed = false
            feedback?.stuck()
        }
    }

    private func win() {
        finishedAt = Date()
        praise = nil
        Task {
            try? await Task.sleep(for: .seconds(0.7))
            guard finishedAt != nil, board.isCleared else { return }   // restarted meanwhile
            phase = .won
            feedback?.win()
        }
    }

    // MARK: - Help

    func useHint() {
        guard phase == .playing, let pair = board.matchablePair() else { return }
        selected = nil
        hinted = [pair.a, pair.b]
        hintsUsed += 1
        feedback?.hint()
    }

    func shuffle() {
        guard phase != .won, finishedAt == nil else { return }
        var rng = SystemRandomNumberGenerator()
        guard board.reshuffle(using: &rng) else {
            shuffleFailed = true
            feedback?.stuck()
            return
        }
        shufflesUsed += 1
        shuffles += 1
        history.removeAll()     // undoing into the old arrangement could strand pairs
        selected = nil
        hinted = []
        combo = 0
        lastMatchAt = nil
        phase = .playing
        feedback?.shuffle()
    }

    func undo() {
        guard canUndo, let move = history.popLast() else { return }
        board.restore(move.pair)
        score -= move.points
        combo = 0
        lastMatchAt = nil
        selected = nil
        hinted = []
        phase = .playing
        shuffleFailed = false
        feedback?.undo()
    }

    func restart() {
        board = config.makeBoard()
        phase = .playing
        selected = nil
        hinted = []
        flights = []
        praise = nil
        combo = 0
        lastMatchAt = nil
        bestCombo = 0
        score = 0
        hintsUsed = 0
        shufflesUsed = 0
        shuffleFailed = false
        startedAt = Date()
        finishedAt = nil
        history = []
        praisedHalfway = false
    }

    // MARK: - Effects

    private func show(_ praise: Praise) {
        self.praise = praise
        feedback?.praise(tier: praise.tier)
        let id = praise.id
        Task {
            try? await Task.sleep(for: .seconds(1.3))
            if self.praise?.id == id { self.praise = nil }
        }
    }

    private func removeFlight(_ id: UUID, after delay: Double) {
        Task {
            try? await Task.sleep(for: .seconds(delay))
            flights.removeAll { $0.id == id }
        }
    }
}
