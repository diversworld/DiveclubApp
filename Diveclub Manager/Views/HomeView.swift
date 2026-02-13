import SwiftUI
import UIKit

private func makeImageURL(_ path: String?) -> URL? {
    guard var path = path, !path.isEmpty else { return nil }
    if !path.hasPrefix("/") { path = "/" + path }
    return URL(string: path, relativeTo: APIClient.shared.baseURL)
}

struct HomeView: View {
    @StateObject private var vm = HomeViewModel()
    @State private var showDetails = false
    @State private var selectedNewsId: Int?
    @State private var showLogin = false
    @State private var showSettings = false
    @State private var showRefreshedBanner = false

    var body: some View {
        Group {
            if vm.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let err = vm.errorMessage {
                ContentUnavailableView("Fehler", systemImage: "exclamationmark.triangle", description: Text(err))
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        if let logoPath = vm.config?.logo, let url = URL(string: logoPath, relativeTo: APIClient.shared.baseURL) {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .empty:
                                    ProgressView()
                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFit()
                                case .failure:
                                    ZStack {
                                        Color.clear
                                        Image(systemName: "photo")
                                            .resizable()
                                            .scaledToFit()
                                            .foregroundStyle(.secondary)
                                            .padding(16)
                                    }
                                    .frame(height: 180)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .clipped()
                                    .cornerRadius(8)
                                }
                            }
                            .padding(.bottom, 8)
                        }
                        if let info = vm.config?.infoText, !info.isEmpty {
                            HTMLTextView(html: info, textStyle: .body)
                        }

                        if !vm.news.isEmpty {
                            Text("News")
                                .font(.headline)

                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(vm.news, id: \.id) { item in
                                    VStack(alignment: .leading, spacing: 8) {
                                        // Headline
                                        Text(item.headline)
                                            .font(.subheadline)
                                            .fontWeight(.semibold)

                                        // Optional image
                                        if let imgURL = makeImageURL(item.image) {
                                            AsyncImage(url: imgURL) { phase in
                                                switch phase {
                                                case .empty:
                                                    ZStack {
                                                        Color.clear
                                                        ProgressView()
                                                    }
                                                    .frame(height: 180)
                                                    .frame(maxWidth: .infinity, alignment: .center)
                                                    .clipped()
                                                    .cornerRadius(8)
                                                case .success(let image):
                                                    image
                                                        .resizable()
                                                        .scaledToFill()
                                                        //.frame(height: 180)
                                                        //.frame(maxWidth: .infinity, alignment: .center)
                                                        .clipped()
                                                case .failure:
                                                    ZStack {
                                                        Color.clear
                                                        Image(systemName: "photo")
                                                            .resizable()
                                                            .scaledToFit()
                                                            .foregroundStyle(.secondary)
                                                            .padding(16)
                                                    }
                                                    .frame(height: 180)
                                                    .frame(maxWidth: .infinity, alignment: .center)
                                                    .clipped()
                                                    .cornerRadius(8)
                                                @unknown default:
                                                    EmptyView()
                                                        .frame(height: 180)
                                                        .frame(maxWidth: .infinity, alignment: .center)
                                                        .clipped()
                                                        .cornerRadius(8)
                                                }
                                            }
                                            .frame(maxHeight: 250)
                                            .cornerRadius(8)
                                            .padding(.bottom, 4)
                                        }

                                        // Date (if available)
                                        if let ts = item.date {
                                            Text(formatDate(ts))
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }

                                        // Teaser
                                        if let teaser = item.teaser, !teaser.isEmpty {
                                            HTMLTextView(html: teaser, textStyle: .footnote)
                                                .foregroundStyle(.secondary)
                                        }

                                        Button {
                                            selectedNewsId = item.id
                                            showDetails = true
                                        } label: {
                                            HStack(spacing: 6) {
                                                Text("Weiterlesen")
                                                Image(systemName: "chevron.right")
                                            }
                                        }
                                        .font(.footnote)
                                        .buttonStyle(.bordered)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.vertical, 6)
                                    .contentShape(Rectangle())
                                }
                            }
                        }

                        // Bottom actions
                        Divider().padding(.vertical, 8)
                        HStack {
                            Button {
                                showLogin = true
                            } label: {
                                Label("Login", systemImage: "person.badge.key")
                            }
                            .buttonStyle(.borderedProminent)

                            Spacer()

                            Button {
                                showSettings = true
                            } label: {
                                Image(systemName: "gearshape")
                                    .imageScale(.large)
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.top)
                }
                .refreshable {
                    // Haptic feedback
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)

                    await vm.load()

                    // Another light feedback after completion (optional)
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()

                    // Defer state mutations to the next run loop tick to avoid modifying state during view updates
                    _ = await MainActor.run {
                        // Show the banner in a new task on the main actor
                        Task { @MainActor in
                            withAnimation(.easeInOut) {
                                showRefreshedBanner = true
                            }
                            try? await Task.sleep(nanoseconds: 1_200_000_000)
                            withAnimation(.easeInOut) {
                                showRefreshedBanner = false
                            }
                        }
                    }
                }
            }
        }
        .task {
            await vm.load()
        }
        .sheet(isPresented: $showDetails) {
            if let id = selectedNewsId {
                NavigationStack { NewsDetailView(newsId: id) }
            }
        }
        .sheet(isPresented: $showLogin) {
            NavigationStack { LoginView() }
        }
        .sheet(isPresented: $showSettings) {
            NavigationStack { SettingsView().navigationTitle("Einstellungen") }
        }
        .overlay(alignment: .top) {
            if showRefreshedBanner {
                TopBanner(title: "Aktualisiert", message: "Inhalte wurden neu geladen.", color: Color("BrandBlue"))
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
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

#Preview {
    NavigationStack { HomeView() }
}
