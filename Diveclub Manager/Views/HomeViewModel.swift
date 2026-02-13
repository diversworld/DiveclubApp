import Foundation
import Combine

struct AppConfigDTO: Decodable {
    let activateApi: Bool?
    let logo: String?
    let infoText: String?
    let newsArchive: Int?
}

struct NewsItemDTO: Decodable, Identifiable {
    let id: Int
    let headline: String
    let teaser: String?
    let date: Int?
    let image: String?
}

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var config: AppConfigDTO?
    @Published var news: [NewsItemDTO] = []

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let cfg: AppConfigDTO = try await APIClient.shared.request("/app/config")
            self.config = cfg

            if let archiveId = cfg.newsArchive {
                let latest: [NewsItemDTO] = try await APIClient.shared.request("/app/news?archive=\(archiveId)&limit=4")
                self.news = latest
            } else {
                self.news = []
            }
        } catch {
            self.errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            self.news = []
        }
    }
}

