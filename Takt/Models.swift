import Foundation

enum StepKind: String, Codable, CaseIterable, Identifiable {
    case work, rest

    var id: String { rawValue }
    var label: String { self == .work ? "Übung" : "Pause" }
}

struct Step: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var seconds: Int
    var kind: StepKind = .work
}

/// A group of steps that is repeated `rounds` times.
struct Block: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var rounds: Int = 3
    var restBetweenRounds: Int = 60
    var restAfterBlock: Int = 120
    var steps: [Step] = []
}

struct Workout: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var prepareSeconds: Int = 10
    var blocks: [Block] = []
}

// MARK: - Flattened timeline

enum PhaseKind {
    case prepare, work, rest
}

struct Phase: Equatable {
    var name: String
    var seconds: Int
    var kind: PhaseKind
    var blockName: String
    var round: Int
    var rounds: Int
    var isRoundStart: Bool
}

extension Workout {
    /// The workout as a linear sequence of timed phases. Steps with zero duration are dropped.
    var phases: [Phase] {
        var result: [Phase] = []
        let blocks = blocks.filter { $0.steps.contains { $0.seconds > 0 } }

        if prepareSeconds > 0, !blocks.isEmpty {
            result.append(Phase(name: "Bereit machen", seconds: prepareSeconds, kind: .prepare,
                                blockName: blocks[0].name, round: 1, rounds: blocks[0].rounds, isRoundStart: false))
        }

        for (blockIndex, block) in blocks.enumerated() {
            let rounds = max(block.rounds, 1)
            for round in 1...rounds {
                var isFirst = true
                for step in block.steps where step.seconds > 0 {
                    let name = step.name.isEmpty ? step.kind.label : step.name
                    result.append(Phase(name: name, seconds: step.seconds, kind: step.kind == .work ? .work : .rest,
                                        blockName: block.name, round: round, rounds: rounds, isRoundStart: isFirst))
                    isFirst = false
                }
                if round < rounds, block.restBetweenRounds > 0 {
                    result.append(Phase(name: "Rundenpause", seconds: block.restBetweenRounds, kind: .rest,
                                        blockName: block.name, round: round, rounds: rounds, isRoundStart: false))
                }
            }
            if blockIndex < blocks.count - 1, block.restAfterBlock > 0 {
                result.append(Phase(name: "Blockpause", seconds: block.restAfterBlock, kind: .rest,
                                    blockName: block.name, round: rounds, rounds: rounds, isRoundStart: false))
            }
        }

        // A trailing rest is pointless: the workout is over.
        while result.last?.kind == .rest { result.removeLast() }
        return result
    }

    var totalSeconds: Int { phases.reduce(0) { $0 + $1.seconds } }
}

// MARK: - Formatting

func formatDuration(_ seconds: Int) -> String {
    let s = max(seconds, 0)
    if s >= 3600 {
        return String(format: "%d:%02d:%02d", s / 3600, (s % 3600) / 60, s % 60)
    }
    return String(format: "%d:%02d", s / 60, s % 60)
}

/// "45 Sekunden", "1 Minute", "2 Minuten 30"
func spokenDuration(_ seconds: Int) -> String {
    let m = seconds / 60, s = seconds % 60
    switch (m, s) {
    case (0, _): return "\(s) Sekunden"
    case (1, 0): return "1 Minute"
    case (_, 0): return "\(m) Minuten"
    case (1, _): return "1 Minute \(s)"
    default: return "\(m) Minuten \(s)"
    }
}

// MARK: - Samples

extension Workout {
    static let samples: [Workout] = [
        Workout(name: "Calisthenics Basis", prepareSeconds: 10, blocks: [
            Block(name: "Push & Pull", rounds: 4, restBetweenRounds: 90, restAfterBlock: 120, steps: [
                Step(name: "Klimmzüge", seconds: 40),
                Step(name: "Pause", seconds: 20, kind: .rest),
                Step(name: "Liegestütze", seconds: 40),
                Step(name: "Pause", seconds: 20, kind: .rest),
                Step(name: "Dips", seconds: 40),
            ]),
            Block(name: "Core", rounds: 3, restBetweenRounds: 30, restAfterBlock: 0, steps: [
                Step(name: "Hollow Hold", seconds: 30),
                Step(name: "Pause", seconds: 15, kind: .rest),
                Step(name: "Plank", seconds: 45),
            ]),
        ]),
        Workout(name: "Tabata", prepareSeconds: 10, blocks: [
            Block(name: "Tabata", rounds: 8, restBetweenRounds: 0, restAfterBlock: 0, steps: [
                Step(name: "Burpees", seconds: 20),
                Step(name: "Pause", seconds: 10, kind: .rest),
            ]),
        ]),
    ]
}
