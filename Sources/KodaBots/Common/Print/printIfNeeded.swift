import Foundation

func printIfNeeded(message: String, priority: MessagePriority = .info) {
    guard KodaBotsSDK.shared.settings?.debugMessagesEnabled == true else { return }
    let priorytyMessage = getPriorityMessage(for: priority)
    print("🤖KodaBotsSDK \(priorytyMessage) -> \(message)")
}

// MARK: - Helpers

private func getPriorityMessage(for priority: MessagePriority) -> String {
    switch priority {
    case .info:
        "ℹ️"
    case .warning:
        "⚠️"
    case .critical:
        "‼️"
    }
}
