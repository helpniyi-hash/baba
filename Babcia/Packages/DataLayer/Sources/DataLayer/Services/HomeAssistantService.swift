import Foundation
import UIKit
import Core

actor HomeAssistantService {
    static let shared = HomeAssistantService()

    private(set) var cameras: [HACamera] = []

    private init() {}

    func fetchCameras(baseURL: String, token: String) async throws {
        var urlString = baseURL
        if !urlString.hasSuffix("/") { urlString += "/" }

        guard let url = URL(string: "\(urlString)api/states") else {
            throw HAError.invalidURL
        }

        var request = URLRequest(url: url, timeoutInterval: 15)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 401 {
                throw HAError.unauthorized
            }
            throw HAError.fetchFailed
        }

        let states = try JSONDecoder().decode([HAState].self, from: data)
        let cameraEntities = states.filter { $0.entityId.hasPrefix("camera.") }

        cameras = cameraEntities.map { state in
            HACamera(
                entityId: state.entityId,
                name: state.attributes.friendlyName ?? state.entityId
                    .replacingOccurrences(of: "camera.", with: "")
                    .replacingOccurrences(of: "_", with: " ")
                    .capitalized,
                state: state.state
            )
        }
    }

    func getSnapshot(baseURL: String, token: String, entityId: String) async throws -> UIImage {
        var urlString = baseURL
        if !urlString.hasSuffix("/") { urlString += "/" }

        guard let url = URL(string: "\(urlString)api/camera_proxy/\(entityId)") else {
            throw HAError.invalidURL
        }

        var request = URLRequest(url: url, timeoutInterval: 30)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw HAError.snapshotFailed
        }

        guard let image = UIImage(data: data) else {
            throw HAError.invalidImageData
        }

        return image
    }

    func testConnection(baseURL: String, token: String) async -> Bool {
        var urlString = baseURL
        if !urlString.hasSuffix("/") { urlString += "/" }

        guard let url = URL(string: "\(urlString)api/") else { return false }

        var request = URLRequest(url: url, timeoutInterval: 10)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            return (response as? HTTPURLResponse)?.statusCode == 200
        } catch {
            return false
        }
    }
}

private struct HAState: Codable {
    let entityId: String
    let state: String
    let attributes: HAAttributes

    enum CodingKeys: String, CodingKey {
        case entityId = "entity_id"
        case state
        case attributes
    }
}

private struct HAAttributes: Codable {
    let friendlyName: String?

    enum CodingKeys: String, CodingKey {
        case friendlyName = "friendly_name"
    }
}

enum HAError: LocalizedError {
    case invalidURL
    case unauthorized
    case fetchFailed
    case snapshotFailed
    case invalidImageData

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid Home Assistant URL"
        case .unauthorized: return "Invalid access token"
        case .fetchFailed: return "Failed to fetch from Home Assistant"
        case .snapshotFailed: return "Failed to get camera snapshot"
        case .invalidImageData: return "Invalid image data"
        }
    }
}
