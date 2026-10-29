import Foundation
import Observation

/// Keeps all workouts in a JSON file in the app's Documents folder.
@Observable
final class WorkoutStore {
    var workouts: [Workout] = [] {
        didSet { save() }
    }

    private static let fileURL = FileManager.default
        .urls(for: .documentDirectory, in: .userDomainMask)[0]
        .appendingPathComponent("workouts.json")

    init() {
        if let data = try? Data(contentsOf: Self.fileURL),
           let saved = try? JSONDecoder().decode([Workout].self, from: data) {
            workouts = saved
        } else {
            workouts = Workout.samples
        }
    }

    func add() -> Workout {
        let workout = Workout(name: "Neues Workout", blocks: [
            Block(name: "Block 1", steps: [
                Step(name: "Übung", seconds: 40),
                Step(name: "Pause", seconds: 20, kind: .rest),
            ]),
        ])
        workouts.append(workout)
        return workout
    }

    func duplicate(_ workout: Workout) {
        var copy = workout
        copy.id = UUID()
        copy.name += " Kopie"
        if let index = workouts.firstIndex(where: { $0.id == workout.id }) {
            workouts.insert(copy, at: index + 1)
        } else {
            workouts.append(copy)
        }
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(workouts) else { return }
        try? data.write(to: Self.fileURL, options: .atomic)
    }
}
