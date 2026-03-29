import Foundation

@MainActor
class NotesStore: ObservableObject {
    @Published var notes: [CaptureNote] = []

    private let userDefaultsKey = "crisp_notes"

    init() {
        loadNotes()
    }

    func loadNotes() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey) else {
            notes = []
            return
        }
        do {
            notes = try JSONDecoder().decode([CaptureNote].self, from: data)
            notes.sort { $0.createdAt > $1.createdAt }
        } catch {
            notes = []
        }
    }

    func saveNote(_ note: CaptureNote) {
        notes.insert(note, at: 0)
        persist()
    }

    func deleteNote(_ note: CaptureNote) {
        notes.removeAll { $0.id == note.id }
        if let audioFileName = note.audioFileName {
            let fileURL = audioFileURL(for: audioFileName)
            try? FileManager.default.removeItem(at: fileURL)
        }
        persist()
    }

    func deleteNote(at offsets: IndexSet) {
        for index in offsets {
            let note = notes[index]
            if let audioFileName = note.audioFileName {
                let fileURL = audioFileURL(for: audioFileName)
                try? FileManager.default.removeItem(at: fileURL)
            }
        }
        notes.remove(atOffsets: offsets)
        persist()
    }

    func updateNote(_ note: CaptureNote) {
        if let index = notes.firstIndex(where: { $0.id == note.id }) {
            notes[index] = note
            persist()
        }
    }

    private func persist() {
        do {
            let data = try JSONEncoder().encode(notes)
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        } catch {
            // silently ignore
        }
    }

    func audioFileURL(for fileName: String) -> URL {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return dir.appendingPathComponent("Crisp").appendingPathComponent(fileName)
    }
}
