import AVFoundation
import SwiftUI

struct WorkoutListView: View {
    @Environment(WorkoutStore.self) private var store
    @State private var path: [UUID] = []
    @State private var running: Workout?
    @State private var showingSettings = false

    var body: some View {
        @Bindable var store = store

        NavigationStack(path: $path) {
            List {
                ForEach(store.workouts) { workout in
                    NavigationLink(value: workout.id) {
                        WorkoutRow(workout: workout) { running = workout }
                    }
                    .contextMenu {
                        Button("Starten", systemImage: "play.fill") { running = workout }
                        Button("Duplizieren", systemImage: "plus.square.on.square") { store.duplicate(workout) }
                    }
                }
                .onDelete { store.workouts.remove(atOffsets: $0) }
                .onMove { store.workouts.move(fromOffsets: $0, toOffset: $1) }
            }
            .overlay {
                if store.workouts.isEmpty {
                    ContentUnavailableView("Keine Workouts", systemImage: "timer",
                                           description: Text("Leg mit + dein erstes Workout an."))
                }
            }
            .navigationTitle("Takt")
            .navigationDestination(for: UUID.self) { id in
                if let index = store.workouts.firstIndex(where: { $0.id == id }) {
                    WorkoutEditorView(workout: $store.workouts[index]) {
                        running = store.workouts[index]
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Einstellungen", systemImage: "gearshape") { showingSettings = true }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Neues Workout", systemImage: "plus") {
                        path.append(store.add().id)
                    }
                }
            }
        }
        .sheet(isPresented: $showingSettings) { SettingsView() }
        .fullScreenCover(item: $running) { workout in
            RunView(workout: workout)
        }
    }
}

private struct WorkoutRow: View {
    let workout: Workout
    let onStart: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(workout.name).font(.headline)
                Text(summary).font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer()
            Button(action: onStart) {
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 34))
                    .foregroundStyle(PhaseKind.work.color)
            }
            .buttonStyle(.borderless)
            .accessibilityLabel("Starten")
        }
        .padding(.vertical, 4)
    }

    private var summary: String {
        let blocks = workout.blocks.count == 1 ? "1 Block" : "\(workout.blocks.count) Blöcke"
        return "\(blocks) · \(formatDuration(workout.totalSeconds))"
    }
}

private struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage(Settings.sound) private var sound = true
    @AppStorage(Settings.voice) private var voice = true
    @AppStorage(Settings.voiceID) private var voiceID = ""
    @State private var voices = Voices.german
    @State private var synth = AVSpeechSynthesizer()

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("Signaltöne", isOn: $sound)
                    Toggle("Sprachansagen", isOn: $voice)
                } footer: {
                    Text("Töne und Ansagen laufen über deine Musik und auch bei gesperrtem Bildschirm. Der Stummschalter am iPhone schaltet sie nicht ab, nur die Lautstärke.")
                }

                if voice {
                    Section {
                        Picker("Stimme", selection: $voiceID) {
                            Text("Automatisch (beste)").tag("")
                            ForEach(voices, id: \.identifier) { v in
                                Text(Voices.label(v)).tag(v.identifier)
                            }
                        }
                        Button("Probehören", systemImage: "speaker.wave.2") {
                            synth.stopSpeaking(at: .immediate)
                            synth.speak(Voices.utterance("Runde 2 von 4. Klimmzüge. 40 Sekunden."))
                        }
                    } header: {
                        Text("Stimme")
                    } footer: {
                        Text("Natürlicher klingen die Premium-Stimmen. Laden: iPhone-Einstellungen → Bedienungshilfen → Gesprochene Inhalte → Stimmen → Deutsch, z. B. Anna oder Petra (Premium). Danach erscheinen sie hier.")
                    }
                }
            }
            .onAppear { voices = Voices.german }
            .navigationTitle("Einstellungen")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") { dismiss() }
                }
            }
        }
    }
}
