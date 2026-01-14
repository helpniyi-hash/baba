import Foundation
import UIKit
import Core

actor GeminiService {
    static let shared = GeminiService()

    private let textModelURL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent"

    private init() {}


    func analyzeRoom(
        roomImage: UIImage,
        character: BabciaCharacter,
        apiKey: String
    ) async throws -> (tasks: [String], advice: String) {
        guard let resizedImage = roomImage.resizedTo(maxDimension: 1024),
              let imageData = resizedImage.jpegData(compressionQuality: 0.8) else {
            throw GeminiError.imageProcessingFailed
        }

        let base64Image = imageData.base64EncodedString()

        let prompt = """
        You are \(character.displayName), with this personality: \(character.tagline).

        Look at this room photo and:

        1. Identify 3-5 specific cleaning/tidying tasks based on what you actually SEE.
        Be specific (e.g., "Pick up the blue shirt from the floor" not "Tidy up").
        Each task should be completable in under 5 minutes.
        Avoid repeating wording across tasks. Each task must be distinct and grounded in visible items.

        2. Write a 2-3 sentence reaction in your character's voice about what you notice.
        \(character.voiceGuidance)
        Avoid clichés and repeated phrases. Keep it fresh each time.

        Respond with this EXACT JSON format:
        {
            "tasks": ["task 1", "task 2", "task 3"],
            "advice": "Your 2-3 sentence character reaction here."
        }
        """

        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": prompt],
                        [
                            "inline_data": [
                                "mime_type": "image/jpeg",
                                "data": base64Image
                            ]
                        ]
                    ]
                ]
            ],
            "generationConfig": [
                "responseMimeType": "application/json"
            ]
        ]

        guard let url = URL(string: "\(textModelURL)?key=\(apiKey)") else {
            throw GeminiError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        request.timeoutInterval = 30

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw GeminiError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw GeminiError.apiError(statusCode: httpResponse.statusCode, message: errorMessage)
        }

        return try parseAnalysisResponse(data)
    }

    func verifyRoom(
        beforeImage: UIImage?,
        afterImage: UIImage,
        tasks: [CleaningTask],
        character: BabciaCharacter,
        apiKey: String
    ) async throws -> RoomVerificationResult {
        guard let resizedAfter = afterImage.resizedTo(maxDimension: 1024),
              let afterData = resizedAfter.jpegData(compressionQuality: 0.8) else {
            throw GeminiError.imageProcessingFailed
        }

        var beforeData: Data?
        if let beforeImage,
           let resizedBefore = beforeImage.resizedTo(maxDimension: 1024),
           let beforeJPEG = resizedBefore.jpegData(compressionQuality: 0.8) {
            beforeData = beforeJPEG
        }

        let tasksPayload = tasks.map { ["id": $0.id.uuidString, "task": $0.title] }
        let tasksJSON = (try? JSONSerialization.data(withJSONObject: tasksPayload))
            .flatMap { String(data: $0, encoding: .utf8) } ?? "[]"

        let prompt = """
        You are verifying whether cleaning tasks were completed. You are \(character.displayName), with this personality: \(character.tagline).

        You will receive:
        - A BEFORE image (last verified room scan) if available.
        - An AFTER image (current scan) to verify against.
        - A task list with IDs.

        Task list JSON:
        \(tasksJSON)

        For each task, decide if it is done based on what you can SEE in the AFTER image compared to BEFORE.
        Only set needsRescan=true if the AFTER image is unusable for most tasks (too dark, too blurry, or clearly not the room).
        If a specific task is unclear, mark that task as "unclear" but keep needsRescan=false.
        Use "verified" when evidence is visible. Use "not_done" when the mess is still present.
        Provide a confidence score from 0.0 to 1.0. Low confidence is acceptable when the evidence is still visible.

        Respond with this EXACT JSON format:
        {
          "needsRescan": false,
          "summary": "1-2 short sentences in your character voice. Avoid repeating phrasing.",
          "tasks": [
            {"id": "UUID", "status": "verified|not_done|unclear", "confidence": 0.0, "note": "short reason"}
          ]
        }
        """

        var parts: [[String: Any]] = [
            ["text": prompt]
        ]

        if let beforeData {
            parts.append([
                "inline_data": [
                    "mime_type": "image/jpeg",
                    "data": beforeData.base64EncodedString()
                ]
            ])
        }

        parts.append([
            "inline_data": [
                "mime_type": "image/jpeg",
                "data": afterData.base64EncodedString()
            ]
        ])

        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": parts
                ]
            ],
            "generationConfig": [
                "responseMimeType": "application/json"
            ]
        ]

        guard let url = URL(string: "\(textModelURL)?key=\(apiKey)") else {
            throw GeminiError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        request.timeoutInterval = 30

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw GeminiError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw GeminiError.apiError(statusCode: httpResponse.statusCode, message: errorMessage)
        }

        return try parseVerificationResponse(data)
    }

    func testAPIKey(_ key: String) async throws -> Bool {
        guard let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models?key=\(key)") else {
            throw GeminiError.invalidURL
        }
        let (_, response) = try await URLSession.shared.data(from: url)
        return (response as? HTTPURLResponse)?.statusCode == 200
    }


    private func parseAnalysisResponse(_ data: Data) throws -> (tasks: [String], advice: String) {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let candidates = json["candidates"] as? [[String: Any]],
              let firstCandidate = candidates.first,
              let content = firstCandidate["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let firstPart = parts.first,
              let text = firstPart["text"] as? String else {
            throw GeminiError.parsingFailed
        }

        let cleanedText = sanitizeResponseText(text)

        if let parsed = parseTasksAndAdvice(from: cleanedText) {
            return parsed
        }

        throw GeminiError.parsingFailed
    }

    private func parseVerificationResponse(_ data: Data) throws -> RoomVerificationResult {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let candidates = json["candidates"] as? [[String: Any]],
              let firstCandidate = candidates.first,
              let content = firstCandidate["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let firstPart = parts.first,
              let text = firstPart["text"] as? String else {
            throw GeminiError.parsingFailed
        }

        let cleanedText = sanitizeResponseText(text)

        if let parsed = parseVerificationJSON(from: cleanedText) {
            return parsed
        }

        throw GeminiError.parsingFailed
    }

    private func sanitizeResponseText(_ text: String) -> String {
        var cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)

        if cleaned.hasPrefix("```json") {
            cleaned = String(cleaned.dropFirst(7))
        } else if cleaned.hasPrefix("```") {
            cleaned = String(cleaned.dropFirst(3))
        }
        if cleaned.hasSuffix("```") {
            cleaned = String(cleaned.dropLast(3))
        }

        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func parseTasksAndAdvice(from text: String) -> (tasks: [String], advice: String)? {
        if let jsonResult = parseJSONTasksAndAdvice(from: text) {
            return jsonResult
        }

        let lines = text.split(separator: "\n").map { String($0) }
        var tasks: [String] = []
        var adviceLines: [String] = []

        for line in lines {
            if let task = parseBulletTask(from: line) {
                tasks.append(task)
            } else {
                adviceLines.append(line)
            }
        }

        if tasks.isEmpty {
            tasks = [
                "Clear one surface",
                "Put away any loose items",
                "Wipe down a visible spot"
            ]
        }

        let advice = adviceLines.joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
        return (tasks: tasks, advice: advice.isEmpty ? "Start small. You have got this." : advice)
    }

    private func parseJSONTasksAndAdvice(from text: String) -> (tasks: [String], advice: String)? {
        if let parsed = parseJSONTasksAndAdvice(from: text.data(using: .utf8)) {
            return parsed
        }

        guard let start = text.firstIndex(of: "{"),
              let end = text.lastIndex(of: "}") else {
            return nil
        }

        let jsonSlice = String(text[start...end])
        return parseJSONTasksAndAdvice(from: jsonSlice.data(using: .utf8))
    }

    private func parseJSONTasksAndAdvice(from data: Data?) -> (tasks: [String], advice: String)? {
        guard let data,
              let response = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let tasks = response["tasks"] as? [String],
              let advice = response["advice"] as? String else {
            return nil
        }

        return (tasks: tasks, advice: advice)
    }

    private func parseVerificationJSON(from text: String) -> RoomVerificationResult? {
        if let parsed = parseVerificationJSON(from: text.data(using: .utf8)) {
            return parsed
        }

        guard let start = text.firstIndex(of: "{"),
              let end = text.lastIndex(of: "}") else {
            return nil
        }

        let jsonSlice = String(text[start...end])
        return parseVerificationJSON(from: jsonSlice.data(using: .utf8))
    }

    private func parseVerificationJSON(from data: Data?) -> RoomVerificationResult? {
        guard let data,
              let response = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let taskItems = response["tasks"] as? [[String: Any]] else {
            return nil
        }

        let summary = response["summary"] as? String ?? ""
        let needsRescan = response["needsRescan"] as? Bool ?? false

        let results: [TaskVerificationResult] = taskItems.compactMap { item in
            guard let idString = item["id"] as? String,
                  let taskID = UUID(uuidString: idString),
                  let statusRaw = item["status"] as? String else {
                return nil
            }

            let normalized = statusRaw.lowercased()
            let status: TaskVerificationStatus
            switch normalized {
            case "verified", "done", "complete":
                status = .verified
            case "not_done", "notdone", "incomplete":
                status = .notDone
            default:
                status = .unclear
            }

            let confidence = (item["confidence"] as? Double) ?? 0.0
            let note = item["note"] as? String
            return TaskVerificationResult(
                taskID: taskID,
                status: status,
                confidence: confidence,
                note: note
            )
        }

        guard !results.isEmpty else { return nil }
        return RoomVerificationResult(tasks: results, summary: summary, needsRescan: needsRescan)
    }

    private func parseBulletTask(from line: String) -> String? {
        var trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        if let firstScalar = trimmed.unicodeScalars.first,
           !CharacterSet.alphanumerics.contains(firstScalar) {
            trimmed = String(trimmed.dropFirst()).trimmingCharacters(in: .whitespacesAndNewlines)
        }

        if let firstChar = trimmed.first, firstChar.isNumber {
            var index = trimmed.startIndex
            while index < trimmed.endIndex, trimmed[index].isNumber {
                index = trimmed.index(after: index)
            }
            if index < trimmed.endIndex, trimmed[index] == "." || trimmed[index] == ")" {
                index = trimmed.index(after: index)
                trimmed = String(trimmed[index...]).trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }

        guard trimmed.count >= 3 else { return nil }
        if trimmed.lowercased().hasPrefix("tasks") || trimmed.lowercased().hasPrefix("advice") {
            return nil
        }

        return trimmed
    }
}

extension UIImage {
    func resizedTo(maxDimension: CGFloat) -> UIImage? {
        let aspectRatio = size.width / size.height
        let newSize: CGSize

        if size.width > size.height {
            newSize = CGSize(width: maxDimension, height: maxDimension / aspectRatio)
        } else {
            newSize = CGSize(width: maxDimension * aspectRatio, height: maxDimension)
        }

        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return resizedImage
    }
}

enum GeminiError: Error, LocalizedError {
    case imageProcessingFailed
    case invalidURL
    case invalidResponse
    case apiError(statusCode: Int, message: String)
    case parsingFailed
    case noImageInResponse

    var errorDescription: String? {
        switch self {
        case .imageProcessingFailed:
            return "Failed to process the image"
        case .invalidURL:
            return "Invalid API URL"
        case .invalidResponse:
            return "Invalid response from API"
        case .apiError(let statusCode, let message):
            return "API error (\(statusCode)): \(message)"
        case .parsingFailed:
            return "Failed to parse API response"
        case .noImageInResponse:
            return "No image found in API response"
        }
    }
}
