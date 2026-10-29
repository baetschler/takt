import SwiftUI

struct WorkoutEditorView: View {
    @Binding var workout: Workout
    let onStart: () -> Void

    var body: some View {
        Form {
            Section {
                TextField("Name", text: $workout.name)
                DurationRow(title: "Vorbereitung", seconds: $workout.prepareSeconds)
            } footer: {
                Text("Gesamtdauer \(formatDuration(workout.totalSeconds))")
            }

            ForEach($workout.blocks) { $block in
                BlockSection(block: $block,
                             isLast: block.id == workout.blocks.last?.id,
                             onDuplicate: { duplicate(block) },
                             onDelete: { workout.blocks.removeAll { $0.id == block.id } })
            }

            Section {
                Button("Block hinzufügen", systemImage: "plus.rectangle.on.rectangle") {
                    workout.blocks.append(Block(name: "Block \(workout.blocks.count + 1)", steps: [
                        Step(name: "Übung", seconds: 40),
                        Step(name: "Pause", seconds: 20, kind: .rest),
                    ]))
                }
            }
        }
        .navigationTitle(workout.name)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Start", systemImage: "play.fill", action: onStart)
                    .disabled(workout.phases.isEmpty)
            }
            ToolbarItem(placement: .secondaryAction) {
                EditButton()
            }
        }
    }

    private func duplicate(_ block: Block) {
        var copy = block
        copy.id = UUID()
        copy.steps = block.steps.map { var s = $0; s.id = UUID(); return s }
        if let index = workout.blocks.firstIndex(where: { $0.id == block.id }) {
            workout.blocks.insert(copy, at: index + 1)
        }
    }
}

private struct BlockSection: View {
    @Binding var block: Block
    let isLast: Bool
    let onDuplicate: () -> Void
    let onDelete: () -> Void

    var body: some View {
        Section {
            TextField("Blockname", text: $block.name)
            Stepper("Runden: \(block.rounds)", value: $block.rounds, in: 1...99)
            if block.rounds > 1 {
                DurationRow(title: "Pause zwischen Runden", seconds: $block.restBetweenRounds)
            }
            if !isLast {
                DurationRow(title: "Pause nach dem Block", seconds: $block.restAfterBlock)
            }

            ForEach($block.steps) { $step in
                StepRow(step: $step)
            }
            .onDelete { block.steps.remove(atOffsets: $0) }
            .onMove { block.steps.move(fromOffsets: $0, toOffset: $1) }

            Menu {
                Button("Übung", systemImage: StepKind.work.symbol) {
                    block.steps.append(Step(name: "", seconds: 40))
                }
                Button("Pause", systemImage: StepKind.rest.symbol) {
                    block.steps.append(Step(name: "Pause", seconds: 20, kind: .rest))
                }
            } label: {
                Label("Schritt hinzufügen", systemImage: "plus.circle")
            }
        } header: {
            HStack {
                Text(block.name.isEmpty ? "Block" : block.name)
                Spacer()
                Menu {
                    Button("Block duplizieren", systemImage: "plus.square.on.square", action: onDuplicate)
                    Button("Block löschen", systemImage: "trash", role: .destructive, action: onDelete)
                } label: {
                    Image(systemName: "ellipsis.circle").imageScale(.large)
                }
                .accessibilityLabel("Block-Optionen")
            }
        } footer: {
            Text("\(block.rounds) × \(formatDuration(roundSeconds))")
        }
    }

    private var roundSeconds: Int { block.steps.reduce(0) { $0 + $1.seconds } }
}

private struct StepRow: View {
    @Binding var step: Step

    var body: some View {
        HStack(spacing: 12) {
            Menu {
                Picker("Art", selection: $step.kind) {
                    ForEach(StepKind.allCases) { kind in
                        Label(kind.label, systemImage: kind.symbol).tag(kind)
                    }
                }
            } label: {
                Image(systemName: step.kind.symbol)
                    .foregroundStyle(step.kind.color)
                    .font(.title3)
            }
            .accessibilityLabel("Art: \(step.kind.label)")

            TextField(step.kind.label, text: $step.name)
            DurationButton(seconds: $step.seconds)
        }
    }
}

struct DurationRow: View {
    let title: String
    @Binding var seconds: Int

    var body: some View {
        LabeledContent(title) {
            DurationButton(seconds: $seconds)
        }
    }
}

struct DurationButton: View {
    @Binding var seconds: Int
    @State private var showingPicker = false

    var body: some View {
        Button(formatDuration(seconds)) { showingPicker = true }
            .monospacedDigit()
            .buttonStyle(.bordered)
            .sheet(isPresented: $showingPicker) {
                DurationPickerSheet(seconds: $seconds)
            }
    }
}

private struct DurationPickerSheet: View {
    @Binding var seconds: Int
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            HStack(spacing: 0) {
                Picker("Minuten", selection: minutes) {
                    ForEach(0..<60) { Text("\($0) min").tag($0) }
                }
                .pickerStyle(.wheel)
                Picker("Sekunden", selection: secondsPart) {
                    ForEach(0..<60) { Text("\($0) s").tag($0) }
                }
                .pickerStyle(.wheel)
            }
            .padding(.horizontal)
            .navigationTitle("Dauer")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") { dismiss() }
                }
            }
        }
        .presentationDetents([.height(300)])
    }

    private var minutes: Binding<Int> {
        Binding(get: { seconds / 60 }, set: { seconds = $0 * 60 + seconds % 60 })
    }

    private var secondsPart: Binding<Int> {
        Binding(get: { seconds % 60 }, set: { seconds = (seconds / 60) * 60 + $0 })
    }
}
