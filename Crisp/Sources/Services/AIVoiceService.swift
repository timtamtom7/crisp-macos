import Foundation
import Speech
import NaturalLanguage

// MARK: - Voice Note wrapper for analysis input

struct VoiceNote {
    let id: UUID
    let transcription: String
    let createdAt: Date

    init(from captureNote: CaptureNote) {
        self.id = captureNote.id
        self.transcription = captureNote.transcription
        self.createdAt = captureNote.createdAt
    }
}

// MARK: - Analysis Result

struct VoiceAnalysis {
    let topics: [String]
    let actionItems: [String]
    let sentiment: Double        // -1.0 (negative) to 1.0 (positive)
    let suggestedTags: [String]
}

// MARK: - AIVoiceService

final class AIVoiceService: @unchecked Sendable {
    static let shared = AIVoiceService()

    private nonisolated(unsafe) let tagger: NLTagger
    private nonisolated(unsafe) let nerTagger: NLTagger
    private nonisolated(unsafe) let sentimentTagger: NLTagger

    private init() {
        tagger = NLTagger(tagSchemes: [.lemma, .lexicalClass, .nameType])
        nerTagger = NLTagger(tagSchemes: [.nameType])
        sentimentTagger = NLTagger(tagSchemes: [.sentimentScore])
    }

    // MARK: - Public API

    func analyzeNote(_ note: VoiceNote) -> VoiceAnalysis {
        let text = note.transcription
        guard !text.isEmpty else {
            return VoiceAnalysis(topics: [], actionItems: [], sentiment: 0, suggestedTags: [])
        }

        let topics = extractTopics(from: text)
        let actionItems = extractActionItems(from: text)
        let sentiment = analyzeSentiment(from: text)
        let tags = suggestTags(from: text, topics: topics)

        return VoiceAnalysis(
            topics: topics,
            actionItems: actionItems,
            sentiment: sentiment,
            suggestedTags: tags
        )
    }

    /// Analyze a batch of notes to find recurring topics
    func analyzeRecurringTopics(notes: [VoiceNote], thisWeek: Bool = true) -> [TopicInsight] {
        let calendar = Calendar.current
        let now = Date()

        let filtered = notes.filter { note in
            !thisWeek || calendar.isDate(note.createdAt, equalTo: now, toGranularity: .weekOfYear)
        }

        var wordCounts: [String: Int] = [:]
        var topicMentions: [String: [(noteId: UUID, date: Date)]] = [:]

        let stopWords = Set([
            "the", "a", "an", "is", "are", "was", "were", "be", "been", "being",
            "have", "has", "had", "do", "does", "did", "will", "would", "could",
            "should", "may", "might", "must", "shall", "can", "need", "dare",
            "to", "of", "in", "for", "on", "with", "at", "by", "from", "as",
            "into", "through", "during", "before", "after", "above", "below",
            "between", "under", "again", "further", "then", "once", "here",
            "there", "when", "where", "why", "how", "all", "each", "few",
            "more", "most", "other", "some", "such", "no", "nor", "not",
            "only", "own", "same", "so", "than", "too", "very", "just",
            "and", "but", "if", "or", "because", "until", "while", "about",
            "against", "this", "that", "these", "those", "am", "it's", "i'm",
            "don't", "don't", "i've", "i'll", "we've", "we'll", "you've",
            "you'll", "they've", "they'll", "what", "which", "who", "whom",
            "their", "they", "them", "his", "her", "its", "our", "your"
        ])

        for note in filtered {
            let words = tokenizeWords(note.transcription)
            for word in words {
                let lower = word.lowercased()
                if !stopWords.contains(lower) && lower.count > 2 {
                    wordCounts[lower, default: 0] += 1
                    topicMentions[lower, default: []].append((note.id, note.createdAt))
                }
            }
        }

        // Return topics mentioned 2+ times
        return topicMentions
            .filter { wordCounts[$0.key] ?? 0 >= 2 }
            .map { word, mentions in
                TopicInsight(
                    topic: word.capitalized,
                    mentionCount: mentions.count,
                    noteIds: mentions.map { $0.noteId }
                )
            }
            .sorted { $0.mentionCount > $1.mentionCount }
    }

    // MARK: - Private Extraction Methods

    private func extractTopics(from text: String) -> [String] {
        tagger.string = text
        var topics: [String] = []
        var seen: Set<String> = []

        // Extract named entities
        nerTagger.string = text
        nerTagger.enumerateTags(
            in: text.startIndex..<text.endIndex,
            unit: .word,
            scheme: .nameType,
            options: [.omitPunctuation, .omitWhitespace, .joinNames]
        ) { tag, range in
            if let tag = tag, tag != .otherWord {
                let entity = String(text[range])
                if !seen.contains(entity.lowercased()) {
                    seen.insert(entity.lowercased())
                    topics.append(entity)
                }
            }
            return true
        }

        // Extract noun phrases as fallback topics
        tagger.string = text
        tagger.enumerateTags(
            in: text.startIndex..<text.endIndex,
            unit: .word,
            scheme: .lexicalClass
        ) { tag, range in
            if let tag = tag, tag == .noun {
                let word = String(text[range])
                if !seen.contains(word.lowercased()) && word.count > 3 {
                    seen.insert(word.lowercased())
                    topics.append(word)
                }
            }
            return true
        }

        return Array(topics.prefix(5))
    }

    private func extractActionItems(from text: String) -> [String] {
        tagger.string = text
        var actionItems: [String] = []

        let actionVerbs: Set<String> = [
            "call", "email", "send", "buy", "pick", "get", "make", "do",
            "check", "review", "finish", "complete", "submit", "schedule",
            "book", "order", "pay", "renew", "cancel", "fix", "clean",
            "prepare", "organize", "start", "stop", "follow", "ask", "tell",
            "remind", "meet", "talk", "write", "read", "learn", "try",
            "find", "look", "watch", "listen", "remember", "plan"
        ]

        let sentences = text.components(separatedBy: CharacterSet(charactersIn: ".!?"))
        for sentence in sentences {
            let words = tokenizeWords(sentence)
            for (index, word) in words.enumerated() {
                let lower = word.lowercased()
                if actionVerbs.contains(lower) && index < words.count - 1 {
                    let remaining = words[(index + 1)...].joined(separator: " ")
                    if !remaining.isEmpty {
                        actionItems.append(remaining.trimmingCharacters(in: .whitespaces))
                        break
                    }
                }
            }
        }

        return Array(actionItems.prefix(3))
    }

    private func analyzeSentiment(from text: String) -> Double {
        sentimentTagger.string = text

        var totalScore: Double = 0
        var count = 0

        sentimentTagger.enumerateTags(
            in: text.startIndex..<text.endIndex,
            unit: .sentence,
            scheme: .sentimentScore
        ) { tag, _ in
            if let tag = tag, let score = Double(tag.rawValue) {
                totalScore += score
                count += 1
            }
            return true
        }

        guard count > 0 else { return 0 }
        return totalScore / Double(count)
    }

    private func suggestTags(from text: String, topics: [String]) -> [String] {
        var tags: Set<String> = []

        // Keyword-based tagging
        let tagMappings: [String: String] = [
            "meeting": "meeting",
            "call": "call",
            "email": "email",
            "buy": "shopping",
            "order": "shopping",
            "money": "finance",
            "pay": "finance",
            "work": "work",
            "project": "work",
            "deadline": "work",
            "doctor": "health",
            "medicine": "health",
            "gym": "fitness",
            "exercise": "fitness",
            "recipe": "food",
            "cook": "food",
            "dinner": "food",
            "lunch": "food",
            "idea": "idea",
            "think": "idea",
            "remember": "reminder",
            "remind": "reminder",
            "birthday": "event",
            "travel": "travel",
            "flight": "travel",
            "trip": "travel"
        ]

        let lower = text.lowercased()
        for (keyword, tag) in tagMappings {
            if lower.contains(keyword) {
                tags.insert(tag)
            }
        }

        // Add top topics as tags
        for topic in topics.prefix(3) {
            let tagCandidate = topic.lowercased()
            if tagCandidate.count > 2 && !["and", "the", "for"].contains(tagCandidate) {
                tags.insert(tagCandidate)
            }
        }

        return Array(tags.prefix(5))
    }

    private func tokenizeWords(_ text: String) -> [String] {
        let pattern = "[\\w]+"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return text.split(separator: " ").map(String.init)
        }
        let range = NSRange(text.startIndex..., in: text)
        let matches = regex.matches(in: text, options: [], range: range)
        return matches.compactMap { match in
            guard let range = Range(match.range, in: text) else { return nil }
            return String(text[range])
        }
    }
}

// MARK: - Topic Insight

struct TopicInsight: Identifiable {
    let id = UUID()
    let topic: String
    let mentionCount: Int
    let noteIds: [UUID]

    var insightText: String {
        "\(topic) — mentioned \(mentionCount) times this week"
    }
}
