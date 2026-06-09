import Foundation

// MARK: - ActivityPhase
// Intentionally does NOT import ActivityKit.
// This makes it visible to all targets (app, widget extension) without requiring
// ActivityKit to be linked to every target.
// Used in FlowStateActivityAttributes.ContentState (Codable) and LiveActivityService.

public enum ActivityPhase: String, Codable, Hashable {
    case work
    case shortBreak
    case longBreak

    var displayName: String {
        switch self {
        case .work:       return "FOCUS"
        case .shortBreak: return "BREAK"
        case .longBreak:  return "LONG BREAK"
        }
    }

    var sfSymbol: String {
        switch self {
        case .work:       return "brain.head.profile"
        case .shortBreak: return "cup.and.saucer.fill"
        case .longBreak:  return "moon.fill"
        }
    }

    var colorHex: String {
        switch self {
        case .work:       return "#8B9CF4"   // indigo
        case .shortBreak: return "#F5A623"   // amber
        case .longBreak:  return "#7ABFA8"   // sage
        }
    }

    // Note: TimerPhase → ActivityPhase conversion lives in LiveActivityService.swift
    // (app target only) so this file stays safe to compile in the Widget Extension target.
}
