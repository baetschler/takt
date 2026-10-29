import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct RunView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var runner: WorkoutRunner
    @State private var confirmingClose = false

    init(workout: Workout) {
        _runner = State(initialValue: WorkoutRunner(workout: workout))
    }

    var body: some View {
        ZStack {
            background.ignoresSafeArea()
            if runner.isFinished {
                finishedView
            } else {
                activeView
            }
        }
        .foregroundStyle(.white)
        .animation(.easeInOut(duration: 0.35), value: runner.index)
        .animation(.easeInOut(duration: 0.2), value: runner.isRunning)
        .onAppear {
            setScreenAlwaysOn(true)
            runner.start()
        }
        .onDisappear {
            setScreenAlwaysOn(false)
            runner.stop()
        }
    }

    private var background: Color {
        guard let phase = runner.current, !runner.isFinished else { return PhaseKind.work.color }
        return runner.isRunning ? phase.kind.color : phase.kind.color.opacity(0.55)
    }

    // MARK: Active

    private var activeView: some View {
        VStack(spacing: 24) {
            HStack {
                Button {
                    runner.pause()
                    confirmingClose = true
                } label: {
                    Image(systemName: "xmark")
                        .font(.title2.weight(.semibold))
                        .frame(width: 44, height: 44)
                }
                .accessibilityLabel("Beenden")
                Spacer()
                VStack(alignment: .trailing) {
                    Text("Noch").font(.caption).opacity(0.8)
                    Text(formatDuration(Int(runner.remainingTotal.rounded(.up))))
                        .font(.headline).monospacedDigit()
                }
            }

            if let phase = runner.current {
                VStack(spacing: 4) {
                    Text(phase.blockName).font(.title3.weight(.semibold))
                    if phase.rounds > 1 {
                        Text("Runde \(phase.round) von \(phase.rounds)").font(.subheadline).opacity(0.85)
                    }
                }

                Spacer(minLength: 0)

                ZStack {
                    Circle().stroke(.white.opacity(0.25), lineWidth: 14)
                    Circle()
                        .trim(from: 0, to: runner.phaseProgress)
                        .stroke(.white, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    VStack(spacing: 8) {
                        Text(phase.name)
                            .font(.title.bold())
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .minimumScaleFactor(0.6)
                        Text(formatDuration(Int(runner.remaining.rounded(.up))))
                            .font(.system(size: 88, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .minimumScaleFactor(0.5)
                            .contentTransition(.numericText(countsDown: true))
                        if !runner.isRunning {
                            Text("Pausiert").font(.headline).opacity(0.9)
                        }
                    }
                    .padding(36)
                }
                .frame(maxWidth: 340)
                .contentShape(Circle())
                .onTapGesture { runner.toggle() }

                Spacer(minLength: 0)

                Group {
                    if let next = runner.next {
                        Text("Als Nächstes: \(next.name) · \(formatDuration(next.seconds))")
                    } else {
                        Text("Letzter Schritt")
                    }
                }
                .font(.headline)
                .opacity(0.9)
            }

            HStack(spacing: 48) {
                controlButton("backward.end.fill", label: "Zurück", size: 28) { runner.back() }
                controlButton(runner.isRunning ? "pause.fill" : "play.fill",
                              label: runner.isRunning ? "Pause" : "Weiter", size: 40) { runner.toggle() }
                    .frame(width: 88, height: 88)
                    .background(.white.opacity(0.22), in: Circle())
                controlButton("forward.end.fill", label: "Überspringen", size: 28) { runner.skip() }
            }
            .padding(.bottom, 8)
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .confirmationDialog("Training beenden?", isPresented: $confirmingClose, titleVisibility: .visible) {
            Button("Beenden", role: .destructive) { dismiss() }
            Button("Weiter trainieren", role: .cancel) { runner.start() }
        }
    }

    private func controlButton(_ symbol: String, label: String, size: CGFloat, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: size, weight: .semibold))
                .frame(width: 64, height: 64)
                .contentShape(Rectangle())
        }
        .accessibilityLabel(label)
    }

    // MARK: Finished

    private var finishedView: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "checkmark.circle.fill").font(.system(size: 96))
            Text("Geschafft!").font(.largeTitle.bold())
            Text(runner.workout.name).font(.title3)
            Text(formatDuration(runner.workout.totalSeconds)).font(.headline).monospacedDigit().opacity(0.85)
            Spacer()
            Button {
                dismiss()
            } label: {
                Text("Fertig")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.white.opacity(0.22), in: RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 24)
        }
    }

    private func setScreenAlwaysOn(_ on: Bool) {
        #if canImport(UIKit)
        UIApplication.shared.isIdleTimerDisabled = on
        #endif
    }
}
