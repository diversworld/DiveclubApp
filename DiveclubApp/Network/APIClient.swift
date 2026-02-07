//
//  APIClient.swift
//  DiveclubApp
//
//  Created by Eckhard Becker on 07.02.26.
//

import Foundation

final class APIClient {

    static let shared = APIClient()
    private init() {}

    private var baseURL: URL {
        URL(string: AppSettingsManager.shared.baseURL)!
    }

    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.httpCookieStorage = HTTPCookieStorage.shared
        config.httpShouldSetCookies = true
        return URLSession(configuration: config)
    }()
    
    func request<T: Decodable>(
        _ path: String,
        method: String = "GET",
        body: Data? = nil
    ) async throws -> T {
        
        var request = URLRequest(url: baseURL.appendingPathComponent(path))
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        print("STATUS CODE:", httpResponse.statusCode)

        if httpResponse.statusCode == 401 {
            await MainActor.run {
                AuthManager.shared.isAuthenticated = false
            }
        }

        if let jsonString = String(data: data, encoding: .utf8) {
            print("SERVER RESPONSE:", jsonString)
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        return try decoder.decode(T.self, from: data)
    }

    func requestWithoutResponse(
        _ path: String,
        method: String,
        body: Data?
    ) async throws {

        var request = URLRequest(url: baseURL.appendingPathComponent(path))
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body

        let (_, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
    }
    
    func testConnection(to urlString: String) async -> Bool {
        
        guard let url = URL(string: urlString) else { return false }
        
        do {
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.timeoutInterval = 10
            
            let (_, response) = try await session.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                return (200...299).contains(httpResponse.statusCode)
            }
            
            return false
        } catch {
            return false
        }
    }
}
