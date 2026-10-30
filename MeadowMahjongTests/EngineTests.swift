import Testing
@testable import MeadowMahjong

@Suite("Free rule")
struct FreeRuleTests {
    @Test("In a row of three, only the ends are free")
    func row() {
        let board = Board(layout: Layout(name: "row", slots: [
            Slot(x: 0, y: 0, z: 0), Slot(x: 2, y: 0, z: 0), Slot(x: 4, y: 0, z: 0), Slot(x: 6, y: 0, z: 0),
        ]))
        #expect(board.isFree(0))
        #expect(!board.isFree(1))
        #expect(!board.isFree(2))
        #expect(board.isFree(3))
    }

    @Test("A tile under another, even half covered, is blocked")
    func covered() {
        let board = Board(layout: Layout(name: "stack", slots: [
            Slot(x: 0, y: 0, z: 0), Slot(x: 1, y: 1, z: 1),
        ]))
        let bottom = board.tiles.first { $0.slot.z == 0 }!.id
        let top = board.tiles.first { $0.slot.z == 1 }!.id
        #expect(!board.isFree(bottom))
        #expect(board.isFree(top))
    }

    @Test("Half a row apart still blocks the side")
    func staggered() {
        let board = Board(layout: Layout(name: "stagger", slots: [
            Slot(x: 0, y: 0, z: 0), Slot(x: 2, y: 1, z: 0), Slot(x: 4, y: 0, z: 0), Slot(x: 8, y: 0, z: 0),
        ]))
        let middle = board.tiles.first { $0.slot == Slot(x: 2, y: 1, z: 0) }!.id
        #expect(!board.isFree(middle))
    }
}

@Suite("Layouts and deals")
struct DealTests {
    @Test("Every layout has whole pairs", arguments: Layouts.progression)
    func evenCounts(layout: Layout) {
        #expect(layout.slots.count >= 20)
        #expect(layout.slots.count % 2 == 0)
    }

    @Test("The first 40 levels deal a board whose own solution clears it", arguments: 1...40)
    func solvable(level: Int) {
        var board = GameConfig.level(level).makeBoard()
        #expect(board.solution.count * 2 == board.tiles.count)
        for pair in board.solution {
            #expect(board.canMatch(pair.a, pair.b))
            board.remove(pair)
        }
        #expect(board.isCleared)
    }

    @Test("Restart deals the same board")
    func deterministic() {
        let a = GameConfig.level(7).makeBoard().tiles.map(\.face)
        let b = GameConfig.level(7).makeBoard().tiles.map(\.face)
        #expect(a == b)
        let day = DayKey(year: 2026, month: 10, day: 30)
        #expect(GameConfig.daily(day).makeBoard().tiles.map(\.face) == GameConfig.daily(day).makeBoard().tiles.map(\.face))
    }

    @Test("Early levels use few faces")
    func variety() {
        let faces = Set(GameConfig.level(1).makeBoard().tiles.map(\.face))
        #expect(faces.count == 5)
    }

    @Test("Shuffle keeps the same faces and stays solvable")
    func shuffle() {
        var board = GameConfig.level(9).makeBoard()
        for pair in board.solution.prefix(6) { board.remove(pair) }
        let before = board.remainingTiles.map(\.face).sorted { "\($0)" < "\($1)" }
        var rng = SeededRandom(seed: 42)
        let reshuffled = board.reshuffle(using: &rng)   // #expect can't call a mutating method
        #expect(reshuffled)
        let after = board.remainingTiles.map(\.face).sorted { "\($0)" < "\($1)" }
        #expect(before == after)
        for pair in board.solution {
            #expect(board.canMatch(pair.a, pair.b))
            board.remove(pair)
        }
        #expect(board.isCleared)
    }
}

@Suite("Game")
@MainActor
struct GameModelTests {
    @Test("Praise words climb with the combo")
    func praiseWords() {
        #expect(GameModel.Praise.text(forCombo: 1) == nil)
        #expect(GameModel.Praise.text(forCombo: 2) == "Good!")
        #expect(GameModel.Praise.text(forCombo: 4) == "Excellent!")
        #expect(GameModel.Praise.text(forCombo: 12) == "Unbelievable!")
    }

    @Test("Quick matches build a combo, undo resets it")
    func combo() {
        let model = GameModel(config: .level(3), feedback: nil)
        let plan = model.board.solution
        model.tap(plan[0].a); model.tap(plan[0].b)
        model.tap(plan[1].a); model.tap(plan[1].b)
        #expect(model.combo == 2)
        #expect(model.praise?.text == "Good!")
        #expect(model.score == 30)
        model.undo()
        #expect(model.combo == 0)
        #expect(model.score == 10)
        #expect(model.tilesLeft == model.board.tiles.count - 2)
    }

    @Test("A blocked tile shakes and is not selected")
    func blocked() {
        let model = GameModel(config: .level(1), feedback: nil)
        let blocked = model.board.tiles.first { !model.board.isFree($0.id) }!.id
        model.tap(blocked)
        #expect(model.selected == nil)
        #expect(model.shakes[blocked] == 1)
    }

    @Test("Hints cost a star")
    func stars() {
        let model = GameModel(config: .level(2), feedback: nil)
        #expect(model.stars == 3)
        model.useHint()
        #expect(model.hinted.count == 2)
        #expect(model.stars == 2)
    }
}
