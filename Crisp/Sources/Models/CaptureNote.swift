import Foundation

struct CaptureNote: Identifiable, Codable, Equatable {
    let id: UUID
    let transcription: String
    let audioFileName: String?
    let createdAt: Date
    var duration: TimeInterval

    init(
        id: UUID = UUID(),
        transcription: String,
        audioFileName: String? = nil,
        createdAt: Date = Date(),
        duration: TimeInterval = 0
    ) {
        self.id = id
        self.transcription = transcription
        self.audioFileName = audioFileName
        self.createdAt = createdAt
        self.duration = duration
    }

    var title: String {
        let words = transcription.split(separator: " ").prefix(5)
        return words.joined(separator: " ")
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: createdAt)
    }

    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
