//
//  APIClient.swift
//  DiveclubApp
//
//  Created by Eckhard Becker on 07.02.26.
//

import Foundation

enum NetworkError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpStatus(Int, body: String?)
    case emptyResponse
    case decoding(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Ungültige URL."
        case .invalidResponse: return "Ungültige Server-Antwort."
        case .httpStatus(let code, let body):
            if let body, !body.isEmpty {
                return "HTTP \(code): \(body)"
            } else {
                return "HTTP \(code)"
            }
        case .emptyResponse:
            return "Server hat keine Daten geliefert (leere Antwort)."
        case .decoding(let msg):
            return "Decoding-Fehler: \(msg)"
        }
    }
}

final class APIClient {
    static let shared = APIClient()

    // ✅ anpassen
    private var baseURL: URL {
        let raw = AppSettingsManager.shared.baseURL
            .trimmingCharacters(in: .whitespacesAndNewlines)

        // Falls User "…/api" ohne Slash speichert, korrigieren wir das hier robust:
        var normalized = raw
        if !normalized.hasSuffix("/") { normalized += "/" }

        return URL(string: normalized)!
    }

    private init() {}

    func request<T: Decodable>(
        _ path: String,
        method: String = "GET",
        body: Data? = nil
    ) async throws -> T {

        guard let url = URL(string: path, relativeTo: baseURL) else {
            throw NetworkError.invalidURL
        }

        var req = URLRequest(url: url)
        req.httpMethod = method

        // ✅ typische Header
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        if body != nil {
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.httpBody = body
        }

        // ✅ falls du Auth nutzt:
        // if let token = AuthManager.shared.token {
        //    req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        // }

        let (data, response) = try await URLSession.shared.data(for: req)

        guard let http = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }

        // Debug: Raw Body
        #if DEBUG
        if let raw = String(data: data, encoding: .utf8) {
            print("➡️ \(method) \(url.absoluteString)")
            print("⬅️ status:", http.statusCode)
            print("⬅️ body:", raw)
        } else {
            print("⬅️ status:", http.statusCode, "(body not utf8 / empty)")
        }
        #endif

        guard (200...299).contains(http.statusCode) else {
            let bodyString = String(data: data, encoding: .utf8)
            throw NetworkError.httpStatus(http.statusCode, body: bodyString)
        }

        guard !data.isEmpty else {
            throw NetworkError.emptyResponse
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        do {
            return try decoder.decode(T.self, from: data)
        } catch let error as DecodingError {
            throw NetworkError.decoding(Self.pretty(decodingError: error))
        } catch {
            throw error
        }
    }

    func requestWithoutResponse(
        _ path: String,
        method: String = "POST",
        body: Data? = nil
    ) async throws {
        // Wenn dein Backend 204 liefert: hier KEIN decode!
        _ = try await request(EmptyResponse.self, path, method: method, body: body)
    }

    private func request<T: Decodable>(
        _ type: T.Type,
        _ path: String,
        method: String,
        body: Data?
    ) async throws -> T {
        try await request(path, method: method, body: body) as T
    }

    private static func pretty(decodingError: DecodingError) -> String {
        switch decodingError {
        case .typeMismatch(let type, let ctx):
            return "typeMismatch(\(type)) at \(ctx.codingPath.map(\.stringValue).joined(separator: ".")): \(ctx.debugDescription)"
        case .valueNotFound(let type, let ctx):
            return "valueNotFound(\(type)) at \(ctx.codingPath.map(\.stringValue).joined(separator: ".")): \(ctx.debugDescription)"
        case .keyNotFound(let key, let ctx):
            return "keyNotFound(\(key.stringValue)) at \(ctx.codingPath.map(\.stringValue).joined(separator: ".")): \(ctx.debugDescription)"
        case .dataCorrupted(let ctx):
            return "dataCorrupted at \(ctx.codingPath.map(\.stringValue).joined(separator: ".")): \(ctx.debugDescription)"
        @unknown default:
            return "unknown decoding error"
        }
    }
    
    /// Testet eine beliebige Base-URL (z.B. aus den Settings), ohne `baseURL` der App zu verändern.
    /// Erwartet, dass `base` auf ".../api" zeigt und hängt dann "/auth/me" an.
    func testConnection(to base: String) async -> Bool {
        do {
            let baseTrimmed = base.trimmingCharacters(in: .whitespacesAndNewlines)
            guard let baseURL = URL(string: baseTrimmed) else { return false }

            // Endpoint relativ zur Base-URL
            guard let url = URL(string: "auth/me", relativeTo: baseURL) else { return false }

            var req = URLRequest(url: url)
            req.httpMethod = "GET"
            req.setValue("application/json", forHTTPHeaderField: "Accept")

            // falls Auth benötigt:
            // if let token = AuthManager.shared.token {
            //     req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            // }

            let (_, response) = try await URLSession.shared.data(for: req)

            guard let http = response as? HTTPURLResponse else { return false }
            return (200...299).contains(http.statusCode)

        } catch {
            #if DEBUG
            print("❌ testConnection(to:) failed:", error.localizedDescription)
            #endif
            return false
        }
    }
}

private struct EmptyResponse: Decodable {}
