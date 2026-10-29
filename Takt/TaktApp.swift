import SwiftUI

@main
struct TaktApp: App {
    @State private var store = WorkoutStore()

    var body: some Scene {
        WindowGroup {
            WorkoutListView()
                .environment(store)
        }
    }
}

extension PhaseKind {
    var color: Color {
        switch self {
        case .prepare: Color(red: 0.95, green: 0.58, blue: 0.10)
        case .work: Color(red: 0.12, green: 0.62, blue: 0.36)
        case .rest: Color(red: 0.16, green: 0.40, blue: 0.82)
        }
    }
}

extension StepKind {
    var color: Color { self == .work ? PhaseKind.work.color : PhaseKind.rest.color }
    var symbol: String { self == .work ? "figure.strengthtraining.functional" : "pause.circle.fill" }
}
