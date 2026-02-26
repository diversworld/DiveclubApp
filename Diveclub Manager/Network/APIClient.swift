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

    private let session: URLSession
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    private init() {
        let config = URLSessionConfiguration.default
        config.httpCookieAcceptPolicy = .always
        config.httpShouldSetCookies = true
        config.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        // ⚠️ diese Timeouts sind "Default". Wir setzen den echten Timeout pro Request.
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 30

        self.session = URLSession(configuration: config)

        // ✅ snake_case -> camelCase
        decoder.keyDecodingStrategy = .convertFromSnakeCase
    }

    // MARK: - Base URL (failsafe + unabhängig von @MainActor)

    /// Liest BaseURL aus UserDefaults direkt, damit APIClient nicht von @MainActor abhängt.
    /// Fallback: contao56.ddev.site
    var baseURL: URL {
        let raw = (UserDefaults.standard.string(forKey: "baseURL") ?? "https://contao56.ddev.site")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return URL(string: raw) ?? URL(string: "https://contao56.ddev.site")!
    }

    /// Timeout aus Settings (UserDefaults) – falls nicht gesetzt: 12s (fail fast)
    private var requestTimeout: TimeInterval {
        let t = UserDefaults.standard.double(forKey: "appTimeout")
        return t == 0 ? 12 : t
    }

    // MARK: - URL + Request

    private func makeURL(_ path: String) throws -> URL {
        let normalized = normalize(path)

        // Wenn baseURL bereits auf .../api zeigt, NICHT nochmal "/api" davor setzen.
        let basePath = baseURL.path
        let needsApiPrefix = !basePath.hasSuffix("/api") && !basePath.hasSuffix("/api/")

        let fullPath = (needsApiPrefix ? "/api" : "") + normalized

        guard let url = URL(string: fullPath, relativeTo: baseURL) else {
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

        // ✅ WICHTIG: Timeout pro Request, damit die App nicht "hängt"
        req.timeoutInterval = requestTimeout

        return req
    }

    /// akzeptiert "/api/xyz" UND "/xyz" UND "xyz"
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
            #if DEBUG
            print("➡️ \(request.httpMethod ?? "GET") \(request.url?.absoluteString ?? "<nil>")")
            #endif

            let (data, resp) = try await session.data(for: request)

            guard let http = resp as? HTTPURLResponse else {
                throw APIError.badStatus(-1, "Keine HTTP-Antwort.")
            }

            #if DEBUG
            print("⬅️ status:", http.statusCode)
            if let s = String(data: data, encoding: .utf8) { print("⬅️ body:", s) }
            #endif

            guard (200...299).contains(http.statusCode) else {
                throw APIError.badStatus(http.statusCode, bodyString(data))
            }

            do {
                return try decoder.decode(T.self, from: data)
            } catch {
                #if DEBUG
                print("❌ Decoding failed for type:", T.self)
                print("⬅️ Raw response body:")
                print(String(data: data, encoding: .utf8) ?? "<non-utf8 data>")
                print("❌ Error:", error)
                #endif
                throw APIError.decoding(error)
            }

        } catch let e as APIError {
            throw e
        } catch {
            // hier landen auch Timeouts / NSURLErrorTimedOut / DNS etc.
            throw APIError.transport(error)
        }
    }

    private func sendNoContent(_ request: URLRequest) async throws {
        do {
            #if DEBUG
            print("➡️ \(request.httpMethod ?? "GET") \(request.url?.absoluteString ?? "<nil>")")
            #endif

            let (data, resp) = try await session.data(for: request)

            guard let http = resp as? HTTPURLResponse else {
                throw APIError.badStatus(-1, "Keine HTTP-Antwort.")
            }

            #if DEBUG
            print("⬅️ status:", http.statusCode)
            if let s = String(data: data, encoding: .utf8) { print("⬅️ body:", s) }
            #endif

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

    func request<T: Decodable>(_ path: String) async throws -> T {
        let req = try makeRequest(method: "GET", path: path)
        return try await send(req, as: T.self)
    }

    func request<T: Decodable>(_ path: String, method: String, body: Data? = nil) async throws -> T {
        let req = try makeRequest(method: method, path: path, body: body)
        return try await send(req, as: T.self)
    }

    func request<T: Decodable, B: Encodable>(_ path: String, method: String, body: B) async throws -> T {
        let data: Data
        do { data = try encoder.encode(body) }
        catch { throw APIError.encoding(error) }
        let req = try makeRequest(method: method, path: path, body: data)
        return try await send(req, as: T.self)
    }

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

    func requestWithoutResponse(_ path: String, method: String) async throws {
        let req = try makeRequest(method: method, path: path, body: nil)
        try await sendNoContent(req)
    }

    // MARK: - Auth

    func clearCookies() {
        let storage = HTTPCookieStorage.shared
        storage.cookies?.forEach { storage.deleteCookie($0) }
    }

    // MARK: - Events

    func getEvents() async throws -> [EventDTO] {
        try await request("/events")
    }
}

// MARK: - Auth Convenience (Member)

extension APIClient {

    private struct LoginResponseDTO: Decodable {
        let success: Bool
        let member: Member?
    }

    func login(username: String, password: String) async throws -> Member {
        let req = LoginRequest(username: username, password: password)
        let resp: LoginResponseDTO = try await request("login", method: "POST", body: req)

        guard resp.success, let member = resp.member else {
            throw APIError.badStatus(200, "Login fehlgeschlagen: success=false oder member fehlt.")
        }
        return member
    }

    func me() async throws -> Member {
        try await request("me", method: "GET")
    }

    func logout() async throws {
        try await requestWithoutResponse("logout", method: "POST")
    }

    func getReservations() async throws -> [EquipmentReservation] {
        try await request("reservations", method: "GET")
    }

    func getReservation(id: Int) async throws -> EquipmentReservation {
        try await request("reservations/\(id)", method: "GET")
    }

    func createReservation(_ payload: CreateReservationRequest) async throws -> EquipmentReservation {
        try await request("reservations", method: "POST", body: payload)
    }
}
// MARK: - Tank checks

extension APIClient {

    func getTankCheckProposals() async throws -> [TankCheckProposalDTO] {
        try await request("/tank-checks")
    }

    func getTankCheckProposal(id: Int) async throws -> TankCheckProposalDetailDTO {
        try await request("/tank-checks/\(id)")
    }

    /// ✅ NEU (umbenannt), falls irgendwo noch das alte Payload-Model genutzt wird
    func bookTankCheckPayload(_ payload: TankCheckBookingPayload) async throws -> TankCheckBookingResponseDTO {
        try await request("/tank-checks/book", method: "POST", body: payload)
    }

    /// ✅ Das ist die Version, die dein TankCheckDetailViewModel aktuell baut
    func bookTankCheck(_ payload: TankCheckBookRequest) async throws -> TankCheckBookingResponseDTO {

        #if DEBUG
        do {
            let data = try encoder.encode(payload)
            print("➡️ POST \(baseURL.absoluteString)/api/tank-checks/book")
            print("➡️ Request JSON:")
            print(String(data: data, encoding: .utf8) ?? "<no utf8>")
        } catch {
            print("❌ Could not encode TankCheckBookRequest:", error)
        }
        #endif

        return try await request("/tank-checks/book", method: "POST", body: payload)
    }
}

// MARK: - Login Payload (falls irgendwo genutzt)

private struct LoginPayload: Codable {
    let username: String
    let password: String
}

extension APIClient {

    /// Testet Erreichbarkeit gegen eine frei eingegebene BaseURL (Settings tempURL).
    /// Erfolg bei 2xx ODER 401/403 (Server erreichbar, aber nicht eingeloggt).
    func testConnection(baseURLString: String) async throws -> Bool {
        let raw = baseURLString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let base = URL(string: raw) else { throw APIError.invalidURL }

        // Wenn baseURL bereits auf .../api zeigt, NICHT nochmal "/api" davor setzen.
        let basePath = base.path
        let needsApiPrefix = !basePath.hasSuffix("/api") && !basePath.hasSuffix("/api/")

        func normalizedPath(_ path: String) -> String {
            if path.hasPrefix("/api/") { return String(path.dropFirst(4)) }
            if path.hasPrefix("/") { return path }
            return "/" + path
        }

        func buildURL(_ path: String) -> URL? {
            let fullPath = (needsApiPrefix ? "/api" : "") + normalizedPath(path)
            return URL(string: fullPath, relativeTo: base)
        }

        // Kandidaten: /me (klein), /events (oft public-ish)
        for path in ["me", "events"] {
            guard let url = buildURL(path) else { continue }

            var req = URLRequest(url: url)
            req.httpMethod = "GET"
            req.setValue("application/json", forHTTPHeaderField: "Accept")
            req.timeoutInterval = 8

            do {
                let (_, resp) = try await URLSession.shared.data(for: req)
                if let http = resp as? HTTPURLResponse {
                    if (200...299).contains(http.statusCode) { return true }
                    if http.statusCode == 401 || http.statusCode == 403 { return true }
                }
            } catch {
                continue
            }
        }

        return false
    }
}
