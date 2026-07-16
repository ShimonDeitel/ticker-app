import Foundation

struct MeetingPreset: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var attendeeCount: Int
    /// Average fully-loaded hourly rate per attendee, in dollars.
    var hourlyRate: Double
    var createdDate: Date

    init(
        id: UUID = UUID(),
        name: String,
        attendeeCount: Int,
        hourlyRate: Double,
        createdDate: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.attendeeCount = attendeeCount
        self.hourlyRate = hourlyRate
        self.createdDate = createdDate
    }

    /// Combined cost accrual rate for the whole room, in dollars per second.
    var costPerSecond: Double {
        (hourlyRate * Double(attendeeCount)) / 3600.0
    }
}

struct MeetingRecord: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var attendeeCount: Int
    var hourlyRate: Double
    var durationSeconds: TimeInterval
    var totalCost: Double
    var endedDate: Date

    init(
        id: UUID = UUID(),
        name: String,
        attendeeCount: Int,
        hourlyRate: Double,
        durationSeconds: TimeInterval,
        totalCost: Double,
        endedDate: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.attendeeCount = attendeeCount
        self.hourlyRate = hourlyRate
        self.durationSeconds = durationSeconds
        self.totalCost = totalCost
        self.endedDate = endedDate
    }
}
