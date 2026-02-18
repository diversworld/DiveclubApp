//
//  HomeViewModel.swift
//  DiveclubApp
//
//  Created by Eckhard Becker on 07.02.26.
//

import Foundation
import Combine

// MARK: - DTOs

struct AppConfigDTO: Codable {   // ✅ Codable (für Cache)
    let activateApi: Bool?
    let logo: String?
    let infoText: String?
    let newsArchive: Int?

    // ✅ Rechtliches aus Config
    let imprint: String?
    let privacy: String?
    let terms: String?
}

struct NewsItemDTO: Codable, Identifiable {  // ✅ Codable (für Cache)
    let id: Int
    let headline: String
    let teaser: String?
    let date: Int?
    let image: String?
}

// MARK: - ViewModel

@MainActor
final class HomeViewModel: ObservableObject {

    @Published var isLoading = false
    @Published var errorMessage: String?

    @Published var config: AppConfigDTO?
    @Published var news: [NewsItemDTO] = []

    // Optional: getrennte Fehler (kannst du im UI anzeigen)
    @Published var configError: String?
    @Published var newsError: String?

    private var loadTask: Task<Void, Never>?
    private let cache = HomeCache()

    func load() async {
        // Vorherigen Load abbrechen (z.B. Pull-to-refresh spammen)
        loadTask?.cancel()

        loadTask = Task { [weak self] in
            guard let self else { return }
            await self.loadInternal()
        }

        await loadTask?.value
    }

    func cancelLoad() {
        loadTask?.cancel()
        loadTask = nil
    }

    // MARK: - Intern

    private func loadInternal() async {
        isLoading = true
        errorMessage = nil
        configError = nil
        newsError = nil

        // ✅ "Last known good" sofort anzeigen => App bleibt bedienbar
        if config == nil, let cachedConfig = cache.loadConfig() {
            config = cachedConfig
        }
        if news.isEmpty, let cachedNews = cache.loadNews() {
            news = cachedNews
        }

        defer { isLoading = false }

        // 1) CONFIG laden (mit Timeout)
        do {
            let cfg: AppConfigDTO = try await withTimeout(seconds: 12) {
                try await APIClient.shared.request("/app/config")
            }
            self.config = cfg
            self.cache.saveConfig(cfg)

            // 2) NEWS laden (nur wenn Archive vorhanden)
            guard let archiveId = cfg.newsArchive else {
                self.news = []
                self.cache.saveNews([])
                return
            }

            do {
                let latest: [NewsItemDTO] = try await withTimeout(seconds: 12) {
                    try await APIClient.shared.request("/app/news?archive=\(archiveId)&limit=0")
                }
                self.news = latest
                self.cache.saveNews(latest)
            } catch {
                self.newsError = friendly(error)
                self.errorMessage = self.errorMessage ?? self.newsError
                // cached News bleibt stehen
            }

        } catch {
            self.configError = friendly(error)
            self.errorMessage = self.configError
            // cached Config/News bleiben sichtbar (Home blockiert nicht)
        }
    }

    private func friendly(_ error: Error) -> String {
        (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
    }
}

// MARK: - Timeout helper

private enum TimeoutError: LocalizedError {
    case timedOut(Int)

    var errorDescription: String? {
        switch self {
        case .timedOut(let s): return "Zeitüberschreitung nach \(s)s."
        }
    }
}

private func withTimeout<T>(
    seconds: Int,
    operation: @escaping () async throws -> T
) async throws -> T {
    try await withThrowingTaskGroup(of: T.self) { group in
        group.addTask { try await operation() }
        group.addTask {
            try await Task.sleep(nanoseconds: UInt64(seconds) * 1_000_000_000)
            throw TimeoutError.timedOut(seconds)
        }

        let result = try await group.next()!
        group.cancelAll()
        return result
    }
}

// MARK: - Cache

private final class HomeCache {
    private let cfgKey = "home.cache.config.v2"
    private let newsKey = "home.cache.news.v2"

    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    func saveConfig(_ cfg: AppConfigDTO) {
        do {
            let data = try encoder.encode(cfg) // ✅ geht, weil AppConfigDTO: Codable
            UserDefaults.standard.set(data, forKey: cfgKey)
        } catch {
            #if DEBUG
            print("❌ HomeCache saveConfig failed:", error)
            #endif
        }
    }

    func loadConfig() -> AppConfigDTO? {
        guard let data = UserDefaults.standard.data(forKey: cfgKey) else { return nil }
        do {
            return try decoder.decode(AppConfigDTO.self, from: data)
        } catch {
            #if DEBUG
            print("❌ HomeCache loadConfig failed:", error)
            #endif
            return nil
        }
    }

    func saveNews(_ items: [NewsItemDTO]) {
        do {
            let data = try encoder.encode(items) // ✅ geht, weil NewsItemDTO: Codable
            UserDefaults.standard.set(data, forKey: newsKey)
        } catch {
            #if DEBUG
            print("❌ HomeCache saveNews failed:", error)
            #endif
        }
    }

    func loadNews() -> [NewsItemDTO]? {
        guard let data = UserDefaults.standard.data(forKey: newsKey) else { return nil }
        do {
            return try decoder.decode([NewsItemDTO].self, from: data)
        } catch {
            #if DEBUG
            print("❌ HomeCache loadNews failed:", error)
            #endif
            return nil
        }
    }
}
