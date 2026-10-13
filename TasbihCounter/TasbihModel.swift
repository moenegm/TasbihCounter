import Foundation
import Observation

// One round, e.g. 33 × سبحان الله
struct Round: Identifiable, Codable, Hashable {
    var id = UUID()
    var target: Int
    var label: String = ""
}

// A preset is a list of rounds. No rounds = free count.
struct Preset: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var rounds: [Round]

    var isFreeCount: Bool { rounds.isEmpty }
    var total: Int { rounds.reduce(0) { $0 + $1.target } }

    static func repeated(_ target: Int, times: Int) -> [Round] {
        (0..<times).map { _ in Round(target: target) }
    }

    static let defaults: [Preset] = [
        Preset(name: "33 · 33 · 34", rounds: [
            Round(target: 33, label: "سبحان الله"),
            Round(target: 33, label: "الحمد لله"),
            Round(target: 34, label: "الله أكبر")
        ]),
        Preset(name: "33 · 33 · 33 · 1", rounds: [
            Round(target: 33, label: "سبحان الله"),
            Round(target: 33, label: "الحمد لله"),
            Round(target: 33, label: "الله أكبر"),
            Round(target: 1, label: "لا إله إلا الله وحده لا شريك له، له الملك وله الحمد وهو على كل شيء قدير")
        ]),
        Preset(name: "100", rounds: [Round(target: 100)]),
        Preset(name: "3 · 3 · 3", rounds: repeated(3, times: 3)),
        Preset(name: "1 · 1 · 1", rounds: repeated(1, times: 3)),
        Preset(name: "1 · 1 · 1 · 1", rounds: repeated(1, times: 4)),
        Preset(name: "1 × 7", rounds: repeated(1, times: 7)),
        Preset(name: "Free count", rounds: [])
    ]
}

// The "brain" of the app: what's selected, which round, the count, and saving.
@Observable
class TasbihStore {
    var presets: [Preset]
    var selectedID: UUID
    var roundIndex: Int
    var count: Int
    var isFinished = false

    // These only exist to trigger different vibrations
    var taps = 0
    var roundEvents = 0
    var finishEvents = 0

    init() {
        let d = UserDefaults.standard
        var loaded = Preset.defaults
        if let data = d.data(forKey: "presets"),
           let saved = try? JSONDecoder().decode([Preset].self, from: data),
           !saved.isEmpty {
            loaded = saved
        }
        var sel = loaded[0].id
        if let s = d.string(forKey: "selectedID"),
           let id = UUID(uuidString: s),
           loaded.contains(where: { $0.id == id }) {
            sel = id
        }
        presets = loaded
        selectedID = sel
        roundIndex = d.integer(forKey: "roundIndex")
        count = d.integer(forKey: "count")
        isFinished = d.bool(forKey: "isFinished")
        if roundIndex >= max(selected.rounds.count, 1) {
            roundIndex = 0
            count = 0
        }
        save()
    }

    var selected: Preset {
        presets.first { $0.id == selectedID } ?? presets[0]
    }

    var currentRound: Round? {
        let rounds = selected.rounds
        guard roundIndex < rounds.count else { return nil }
        return rounds[roundIndex]
    }

    func tap() {
        guard !isFinished else { return }
        count += 1

        if let round = currentRound, count >= round.target {
            if roundIndex + 1 < selected.rounds.count {
                roundIndex += 1        // next round
                count = 0
                roundEvents += 1
            } else {
                isFinished = true      // whole preset done
                finishEvents += 1
            }
        } else {
            taps += 1
        }
        save()
    }

    func select(_ id: UUID) {
        selectedID = id
        reset()
    }

    func reset() {
        roundIndex = 0
        count = 0
        isFinished = false
        save()
    }
    
    // Called whenever presets are edited
    func presetsChanged() {
        if presets.isEmpty { presets = Preset.defaults }
        if !presets.contains(where: { $0.id == selectedID }) {
            selectedID = presets[0].id
            reset()
        } else if roundIndex >= max(selected.rounds.count, 1) {
            reset()
        } else {
            save()
        }
    }

    func restoreDefaults() {
        presets = Preset.defaults
        selectedID = presets[0].id
        reset()
    }
    
    func save() {
        let d = UserDefaults.standard
        if let data = try? JSONEncoder().encode(presets) {
            d.set(data, forKey: "presets")
        }
        d.set(selectedID.uuidString, forKey: "selectedID")
        d.set(roundIndex, forKey: "roundIndex")
        d.set(count, forKey: "count")
        d.set(isFinished, forKey: "isFinished")
    }
}
