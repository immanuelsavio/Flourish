import Foundation

struct ScheduledTransfer: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var userId: UUID
    var fromAccountId: UUID
    var toAccountId: UUID
    var amount: Double
    var scheduledDate: Date
    var recurrenceDays: Int? = nil
    var notes: String?
    var isCompleted: Bool = false
    var completedDate: Date?
}
