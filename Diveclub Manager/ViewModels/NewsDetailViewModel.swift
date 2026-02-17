import Foundation
import Combine

struct NewsDetailDTO: Decodable {
    let id: Int
    let headline: String?
    let teaser: String?
    let text: String?
    let image: String?
    let date: Int?
}

@MainActor
final class NewsDetailViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var detail: NewsDetailDTO?

    func load(newsId: Int) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let d: NewsDetailDTO = try await APIClient.shared.request("/app/news/details?id=\(newsId)")
            self.detail = d
        } catch {
            self.errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            self.detail = nil
        }
    }
}
