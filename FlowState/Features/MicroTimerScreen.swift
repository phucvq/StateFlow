import SwiftUI

// MicroTimerScreen and MicroCompleteView are defined in MicroCommitmentScreen.swift
// This file is intentionally minimal — kept for project organization clarity.

// MARK: - Micro Flow Router
// Used by HomeScreen to route between micro sub-screens
struct MicroFlowView: View {
    @Environment(TimerViewModel.self) private var timerVM
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        switch timerVM.timerState {
        case .idle where timerVM.isMicroMode:
            MicroCommitmentScreen()
        case .workRunning, .workPaused:
            if timerVM.isMicroMode && timerVM.workDuration <= 2 * 60 + 1 {
                MicroTimerScreen()
            } else {
                TimerScreen()
            }
        case .sessionComplete:
            if timerVM.isMicroMode {
                MicroCompleteView(
                    onContinue: { duration in
                        timerVM.continueMicroCommitment(withDuration: duration)
                    },
                    onStop: {
                        timerVM.resetToIdle()
                    }
                )
            }
        default:
            TimerScreen()
        }
    }
}
