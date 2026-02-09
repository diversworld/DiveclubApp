//
//  APIClient.swift
//  DiveclubApp
//
//  Created by Eckhard Becker on 07.02.26.
//

import Foundation

enum APIError: Error, LocalizedError {
    case invalidURL
    case badStatus(Int, String?)
    case decoding(Error)
    case encoding(Error)
    case transport(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Ungültige URL."
        case .badStatus(let code, let body): return "Serverfehler (\(code)). \(body ?? "")"
        case .decoding(let e): return "Antwort konnte nicht gelesen werden: \(e.localizedDescription)"
        case .encoding(let e): return "Request konnte nicht erstellt werden: \(e.localizedDescription)"
        case .transport(let e): return "Netzwerkfehler: \(e.localizedDescription)"
        }
    }
}

final class APIClient {
    static let shared = APIClient()

    /// Base URL eurer Site (z.B. https://contao56.ddev.site)
    var baseURL: URL = URL(string: "https://contao56.ddev.site")!

    private let session: URLSession
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    private init() {
        let config = URLSessionConfiguration.default
        config.httpCookieAcceptPolicy = .always
        config.httpShouldSetCookies = true
        config.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 30

        self.session = URLSession(configuration: config)
    }

    // MARK: - URL + Request

    private func makeURL(_ path: String) throws -> URL {
        let normalized = normalize(path)
        guard let url = URL(string: "/api" + normalized, relativeTo: baseURL) else {
            throw APIError.invalidURL
        }
        return url
    }

    private func makeRequest(method: String, path: String, body: Data? = nil) throws -> URLRequest {
        let url = try makeURL(path)
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.httpBody = body
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        if body != nil { req.setValue("application/json", forHTTPHeaderField: "Content-Type") }
        return req
    }

    /// akzeptiert "/api/xyz" UND "/xyz"
    private func normalize(_ path: String) -> String {
        if path.hasPrefix("/api/") { return String(path.dropFirst(4)) } // remove "/api"
        if path.hasPrefix("/") { return path }
        return "/" + path
    }

    private func bodyString(_ data: Data?) -> String? {
        guard let data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    // MARK: - Core send

    private func send<T: Decodable>(_ request: URLRequest, as: T.Type) async throws -> T {
        do {
            let (data, resp) = try await session.data(for: request)
            guard let http = resp as? HTTPURLResponse else {
                throw APIError.badStatus(-1, "Keine HTTP-Antwort.")
            }
            guard (200...299).contains(http.statusCode) else {
                throw APIError.badStatus(http.statusCode, bodyString(data))
            }
            do {
                return try decoder.decode(T.self, from: data)
            } catch {
                throw APIError.decoding(error)
            }
        } catch let e as APIError {
            throw e
        } catch {
            throw APIError.transport(error)
        }
    }

    private func sendNoContent(_ request: URLRequest) async throws {
        do {
            let (data, resp) = try await session.data(for: request)
            guard let http = resp as? HTTPURLResponse else {
                throw APIError.badStatus(-1, "Keine HTTP-Antwort.")
            }
            guard (200...299).contains(http.statusCode) else {
                throw APIError.badStatus(http.statusCode, bodyString(data))
            }
        } catch let e as APIError {
            throw e
        } catch {
            throw APIError.transport(error)
        }
    }

    // MARK: - Legacy-compatible API (dein bestehender Code)

    /// Alt: request("/path") -> T
    func request<T: Decodable>(_ path: String) async throws -> T {
        let req = try makeRequest(method: "GET", path: path)
        return try await send(req, as: T.self)
    }

    /// Alt: request("/path", method: "GET/POST/...", body: Data?) -> T
    func request<T: Decodable>(_ path: String, method: String, body: Data? = nil) async throws -> T {
        let req = try makeRequest(method: method, path: path, body: body)
        return try await send(req, as: T.self)
    }

    /// Alt: request("/path", method: "...", body: Encodable) -> T
    func request<T: Decodable, B: Encodable>(_ path: String, method: String, body: B) async throws -> T {
        let data: Data
        do { data = try encoder.encode(body) }
        catch { throw APIError.encoding(error) }
        let req = try makeRequest(method: method, path: path, body: data)
        return try await send(req, as: T.self)
    }

    /// Alt: requestWithoutResponse("/path", method: "PATCH/POST", body: Encodable?)
    func requestWithoutResponse<B: Encodable>(_ path: String, method: String, body: B?) async throws {
        let data: Data?
        if let body {
            do { data = try encoder.encode(body) }
            catch { throw APIError.encoding(error) }
        } else {
            data = nil
        }
        let req = try makeRequest(method: method, path: path, body: data)
        try await sendNoContent(req)
    }

    /// Alt: requestWithoutResponse("/path", method: "PATCH/POST") (ohne body)
    func requestWithoutResponse(_ path: String, method: String) async throws {
        let req = try makeRequest(method: method, path: path, body: nil)
        try await sendNoContent(req)
    }

    // MARK: - Auth

    func login(username: String, password: String) async throws -> MeDTO {
        let payload = LoginPayload(username: username, password: password)
        return try await request("/login", method: "POST", body: payload)
    }

    func logout() async throws {
        try await requestWithoutResponse("/logout", method: "POST")
        clearCookies()
    }

    func me() async throws -> MeDTO {
        try await request("/me")
    }

    func clearCookies() {
        let storage = HTTPCookieStorage.shared
        storage.cookies?.forEach { storage.deleteCookie($0) }
    }

    // MARK: - Tank checks

    func getTankCheckProposals() async throws -> [TankCheckProposalDTO] {
        try await request("/tank-checks")
    }

    func getTankCheckProposal(id: Int) async throws -> TankCheckProposalDetailDTO {
        try await request("/tank-checks/\(id)")
    }

    func bookTankCheck(_ payload: TankCheckBookingPayload) async throws -> TankCheckBookingResponseDTO {
        try await request("/tank-checks/book", method: "POST", body: payload)
    }

    // MARK: - Events

    func getEvents() async throws -> [EventDTO] {
        try await request("/events")
    }
}

// MARK: - Auth DTOs

private struct LoginPayload: Codable {
    let username: String
    let password: String
}

struct MeDTO: Codable, Equatable {
    let id: String?
    let username: String?
    let firstname: String?
    let lastname: String?
    let email: String?
    let role: String?

    var fullName: String {
        [firstname, lastname].compactMap { $0 }.joined(separator: " ").trimmingCharacters(in: .whitespaces)
    }

    var isInstructor: Bool {
        (role ?? "").lowercased().contains("instructor")
    }
}
