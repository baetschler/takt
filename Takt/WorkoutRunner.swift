import Foundation
import Observation

/// Runs a workout's phases against the wall clock. Timing is based on an end date,
/// not on counting ticks, so it doesn't drift and survives short app stalls.
@Observable
final class WorkoutRunner {
    let workout: Workout
    let phases: [Phase]

    private(set) var index = 0
    private(set) var remaining: TimeInterval = 0
    private(set) var isRunning = false
    private(set) var isFinished = false

    @ObservationIgnored private let cues: CueEngine
    @ObservationIgnored private var endDate: Date?
    @ObservationIgnored private var timer: Timer?
    @ObservationIgnored private var lastBeep: Int?
    @ObservationIgnored private var hasStarted = false

    init(workout: Workout, cues: CueEngine = CueEngine()) {
        self.workout = workout
        self.phases = workout.phases
        self.cues = cues
        remaining = TimeInterval(phases.first?.seconds ?? 0)
        isFinished = phases.isEmpty
    }

    var current: Phase? { phases.indices.contains(index) ? phases[index] : nil }
    var next: Phase? { phases.indices.contains(index + 1) ? phases[index + 1] : nil }

    var phaseProgress: Double {
        guard let current, current.seconds > 0 else { return 1 }
        return 1 - remaining / Double(current.seconds)
    }

    var remainingTotal: TimeInterval {
        remaining + phases.dropFirst(index + 1).reduce(0) { $0 + Double($1.seconds) }
    }

    // MARK: Controls

    func start() {
        guard !isFinished, !isRunning else { return }
        if !hasStarted {
            hasStarted = true
            cues.begin()
            announce()
        }
        endDate = Date().addingTimeInterval(remaining)
        isRunning = true
        let timer = Timer(timeInterval: 0.05, repeats: true) { [weak self] _ in self?.update() }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    func pause() {
        guard isRunning else { return }
        update()
        isRunning = false
        timer?.invalidate()
        timer = nil
        endDate = nil
    }

    func toggle() {
        isRunning ? pause() : start()
    }

    func skip() {
        guard !isFinished else { return }
        jump(to: index + 1)
    }

    /// Restarts the current phase, or goes to the previous one if the current phase just began.
    func back() {
        guard let current, !isFinished else { return }
        let elapsed = Double(current.seconds) - remaining
        jump(to: elapsed > 2 || index == 0 ? index : index - 1)
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        isRunning = false
        if hasStarted { cues.end() }
    }

    // MARK: Internals

    private func jump(to newIndex: Int) {
        lastBeep = nil
        guard newIndex < phases.count else {
            finish()
            return
        }
        index = newIndex
        remaining = Double(phases[newIndex].seconds)
        if isRunning { endDate = Date().addingTimeInterval(remaining) }
        if hasStarted { announce() }
    }

    private func update() {
        guard isRunning, var end = endDate else { return }
        var left = end.timeIntervalSinceNow

        // Phase over: chain the next one onto the old end date so overshoot isn't lost.
        while left <= 0 {
            guard index + 1 < phases.count else {
                remaining = 0
                finish()
                return
            }
            index += 1
            lastBeep = nil
            end = end.addingTimeInterval(Double(phases[index].seconds))
            left = end.timeIntervalSinceNow
            announce()
        }

        endDate = end
        remaining = left

        let second = Int(left.rounded(.up))
        if second <= 3, second != lastBeep, (current?.seconds ?? 0) > 3 {
            lastBeep = second
            cues.tick()
        }
    }

    private func finish() {
        timer?.invalidate()
        timer = nil
        isRunning = false
        isFinished = true
        index = phases.count
        remaining = 0
        cues.finish()
        cues.say("Geschafft!")
    }

    private func announce() {
        guard let current else { return }
        cues.go()
        switch current.kind {
        case .prepare:
            cues.say("Bereit machen. Als Erstes \(next?.name ?? "")")
        case .work:
            var text = "\(current.name). \(spokenDuration(current.seconds))"
            if current.isRoundStart, current.rounds > 1 {
                text = "Runde \(current.round) von \(current.rounds). " + text
            }
            cues.say(text)
        case .rest:
            cues.say(next.map { "\(current.name). Danach \($0.name)" } ?? current.name)
        }
    }
}
