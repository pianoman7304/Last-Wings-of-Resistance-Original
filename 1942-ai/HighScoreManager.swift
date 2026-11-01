import Foundation

struct HighScoreEntry: Codable {
    var name: String // 6 letters
    var score: Int
}

class HighScoreManager {
    static let shared = HighScoreManager()
    private let fileName = "highscores.json"
    private(set) var scores: [HighScoreEntry] = []
    
    private init() {
        load()
    }
    
    func addScore(name: String, score: Int) {
        let entry = HighScoreEntry(name: String(name.prefix(6)), score: score)
        scores.append(entry)
        scores.sort { $0.score > $1.score }
        if scores.count > 100 { scores = Array(scores.prefix(100)) }
        save()
    }
    
    private func save() {
        let url = getFileURL()
        do {
            let data = try JSONEncoder().encode(scores)
            try data.write(to: url)
        } catch {
            print("Failed to save high scores: \(error)")
        }
    }
    
    private func load() {
        let url = getFileURL()
        if let data = try? Data(contentsOf: url),
           let loaded = try? JSONDecoder().decode([HighScoreEntry].self, from: data) {
            scores = loaded
        } else {
            // Initialize with 100 empty scores
            scores = Array(repeating: HighScoreEntry(name: "noname", score: 0), count: 100)
            save()
        }
    }
    
    private func getFileURL() -> URL {
        let fm = FileManager.default
        let urls = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        let dir = urls[0].appendingPathComponent("1942-ai", isDirectory: true)
        if !fm.fileExists(atPath: dir.path) {
            try? fm.createDirectory(at: dir, withIntermediateDirectories: true, attributes: nil)
        }
        return dir.appendingPathComponent(fileName)
    }
}
