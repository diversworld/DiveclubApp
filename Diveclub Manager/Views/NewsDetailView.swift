import SwiftUI

struct NewsDetailView: View {
    let newsId: Int
    @StateObject private var vm = NewsDetailViewModel()

    var body: some View {
        Group {
            if vm.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let err = vm.errorMessage {
                ContentUnavailableView("Fehler", systemImage: "exclamationmark.triangle", description: Text(err))
            } else if let news = vm.detail {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        if let headline = news.headline {
                            Text(headline)
                                .font(.title2)
                                .bold()
                        }

                        if let ts = news.date {
                            Text(formatDate(ts))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        if let imgURL = makeImageURL(news.image) {
                            AsyncImage(url: imgURL) { phase in
                                switch phase {
                                case .empty:
                                    ProgressView()
                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFit()
                                case .failure:
                                    placeholderImage
                                @unknown default:
                                    EmptyView()
                                }
                            }
                            .frame(maxHeight: 250)
                            .cornerRadius(8)
                        } else {
                            // Platzhalter, wenn kein Bild vorhanden ist
                            placeholderImage
                                .frame(maxHeight: 180)
                                .cornerRadius(8)
                        }

                        if let teaser = news.teaser, !teaser.isEmpty {
                            HTMLTextView(html: teaser, textStyle: .body)
                        }

                        if let text = news.text, !text.isEmpty {
                            HTMLTextView(html: text, textStyle: .body)
                        }
                    }
                    .padding()
                }
            } else {
                ContentUnavailableView("Keine Daten", systemImage: "doc.text.magnifyingglass")
            }
        }
        .navigationTitle("News")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await vm.load(newsId: newsId)
        }
    }

    private var placeholderImage: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.15))
            Image(systemName: "photo")
                .resizable()
                .scaledToFit()
                .frame(height: 60)
                .foregroundStyle(.secondary)
        }
    }
}
private func formatDate(_ timestamp: Int) -> String {
    let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
    let f = DateFormatter()
    f.locale = Locale(identifier: "de_DE")
    f.dateStyle = .medium
    return f.string(from: date)
}

private func makeImageURL(_ path: String?) -> URL? {
    guard var path = path, !path.isEmpty else { return nil }
    if !path.hasPrefix("/") { path = "/" + path }
    return URL(string: path, relativeTo: APIClient.shared.baseURL)
}

