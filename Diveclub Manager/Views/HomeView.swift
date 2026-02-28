//
//  HomeView.swift
//  DiveclubApp
//
//  Created by Eckhard Becker on 09.02.26.
//

import SwiftUI
import UIKit

private func makeImageURL(_ path: String?) -> URL? {
    guard var path = path, !path.isEmpty else { return nil }
    if !path.hasPrefix("/") { path = "/" + path }
    return URL(string: path, relativeTo: APIClient.shared.baseURL)
}

struct HomeView: View {
    @StateObject private var vm = HomeViewModel()
    @StateObject private var auth = AuthManager.shared

    @State private var selectedNewsId: Int? = nil
    @State private var showLogin = false
    @State private var showSettings = false
    @State private var showRefreshedBanner = false

    private var isLoggedIn: Bool { auth.isLoggedIn }

    // Höhe der fixen Fußzeile (damit ScrollView unten Platz lässt)
    private let bottomBarHeight: CGFloat = 86

    var body: some View {
        ZStack(alignment: .top) {

            // ✅ Statusbar/SafeArea oben blau
            StatusBarBackground(color: Color("BrandBlue"))

            content
        }
        .task { await vm.load() }
        .navigationTitle("Home")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            if isLoggedIn {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            // Optional: Navigate to Profile if available
                            // e.g., open a ProfileView if desired
                        } label: {
                            Label("Profil", systemImage: "person.circle")
                        }

                        Button {
                            // Optional: Open settings for logged-in user if needed
                            showSettings = true
                        } label: {
                            Label("Einstellungen", systemImage: "gearshape")
                        }

                        Divider()

                        Button(role: .destructive) {
                            Task { await AuthManager.shared.logout() }
                        } label: {
                            Label("Logout", systemImage: "rectangle.portrait.and.arrow.right")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            } else {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showLogin = true
                    } label: {
                        Image(systemName: "person.badge.key")
                    }
                }
            }
        }
        .sheet(item: Binding(
            get: { selectedNewsId.map(IdentifiedInt.init) },
            set: { selectedNewsId = $0?.value }
        )) { item in
            NavigationStack { NewsDetailView(newsId: item.value) }
        }
        .sheet(isPresented: Binding(
            get: { showLogin && !isLoggedIn },
            set: { showLogin = $0 }
        )) {
            NavigationStack { LoginView() }
        }
        .sheet(isPresented: Binding(
            get: { showSettings && !isLoggedIn },
            set: { showSettings = $0 }
        )) {
            NavigationStack { SettingsView().navigationTitle("Einstellungen") }
        }
        .overlay(alignment: .top) {
            if showRefreshedBanner {
                TopBanner(title: "Aktualisiert", message: "Inhalte wurden neu geladen.", color: Color("BrandBlue"))
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }

    // MARK: - Main content
    @ViewBuilder
    private var content: some View {
        Group {
            if vm.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

            } else if let err = vm.errorMessage {
                ContentUnavailableView("Fehler", systemImage: "exclamationmark.triangle", description: Text(err))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .overlay(alignment: .bottom) {
                        // hier bleibt alles wie gehabt
                        HStack {
                            Button { Task { await vm.load() } } label: {
                                Label("Erneut versuchen", systemImage: "arrow.clockwise")
                            }
                            .buttonStyle(.borderedProminent)

                            Spacer()

                            Button { showSettings = true } label: {
                                Label("Einstellungen", systemImage: "gearshape")
                            }
                            .buttonStyle(.bordered)
                        }
                        .padding()
                    }

            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {

                        header

                        if let info = vm.config?.infoText, !info.isEmpty {
                            HTMLTextView(html: info, textStyle: .body)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                        }

                        newsSection
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .refreshable {
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)

                    await vm.load()
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()

                    Task { @MainActor in
                        await Task.yield()
                        withAnimation(.easeInOut) { showRefreshedBanner = true }
                        try? await Task.sleep(nanoseconds: 1_200_000_000)
                        withAnimation(.easeInOut) { showRefreshedBanner = false }
                    }
                }
                // ✅ Fußzeile fest “angedockt”, wie TabBar
                
            }
        }
    }

    // MARK: - Header (unverändert)
    private var header: some View {
        VStack(spacing: 12) {
            if let logoPath = vm.config?.logo,
               let url = URL(string: logoPath, relativeTo: APIClient.shared.baseURL) {

                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(height: 96)
                            .frame(maxWidth: .infinity)

                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                            .frame(height: 96)
                            .frame(maxWidth: .infinity)

                    case .failure:
                        Image(systemName: "photo")
                            .resizable()
                            .scaledToFit()
                            .foregroundStyle(.white.opacity(0.9))
                            .padding(16)
                            .frame(height: 96)
                            .frame(maxWidth: .infinity)

                    @unknown default:
                        EmptyView()
                            .frame(height: 96)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
            }
        }
        .frame(maxWidth: .infinity)
        .background(Color("BrandBlue"))
        .foregroundStyle(.white)
        .ignoresSafeArea(edges: .top)
    }

    // MARK: - News Section (unverändert)
    @ViewBuilder
    private var newsSection: some View {
        if !vm.news.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("News")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.horizontal, 16)

                VStack(spacing: 14) {
                    ForEach(vm.news, id: \.id) { item in
                        newsCard(item)
                            .padding(.horizontal, 16)
                    }
                }
            }
        }
    }

    private func newsCard(_ item: NewsItemDTO) -> some View {
        VStack(alignment: .leading, spacing: 10) {

            Text(item.headline)
                .font(.title3)
                .fontWeight(.semibold)

            if let imgURL = makeImageURL(item.image) {
                AsyncImage(url: imgURL) { phase in
                    switch phase {
                    case .empty:
                        ZStack { ProgressView() }
                            .frame(height: 180)
                            .frame(maxWidth: .infinity)

                    case .success(let image):
                        image
                            .resizable()
                            .frame(height: 180)
                            .frame(maxWidth: .infinity)
                            .clipped()

                    case .failure:
                        placeholderImage
                            .frame(height: 180)
                            .frame(maxWidth: .infinity)

                    @unknown default:
                        placeholderImage
                            .frame(height: 180)
                            .frame(maxWidth: .infinity)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }

            if let ts = item.date {
                Text(formatDate(ts))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let teaser = item.teaser, !teaser.isEmpty {
                HTMLTextView(html: teaser, textStyle: .footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Button {
                selectedNewsId = item.id
            } label: {
                HStack(spacing: 6) {
                    Text("Weiterlesen")
                    Image(systemName: "chevron.right")
                }
            }
            .font(.footnote)
            .buttonStyle(.bordered)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(radius: 6, y: 2)
    }

    private var placeholderImage: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.12))
            Image(systemName: "photo")
                .resizable()
                .scaledToFit()
                .frame(height: 44)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Bottom actions (unverändert)
    private var bottomActions: some View {
        VStack(spacing: 12) {
            HStack {
                Button { showLogin = true } label: {
                    Image(systemName: "person.badge.key").imageScale(.large)
                }
                .buttonStyle(.bordered)

                Spacer()

                Button { showSettings = true } label: {
                    Image(systemName: "gearshape").imageScale(.large)
                }
                .buttonStyle(.bordered)
            }
        }
    }
}

// MARK: - Helpers

private func formatDate(_ timestamp: Int) -> String {
    let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
    let f = DateFormatter()
    f.locale = Locale(identifier: "de_DE")
    f.dateStyle = .medium
    return f.string(from: date)
}

private struct IdentifiedInt: Identifiable {
    let value: Int
    var id: Int { value }
}

private struct StatusBarBackground: View {
    let color: Color
    var body: some View {
        GeometryReader { proxy in
            color
                .frame(height: proxy.safeAreaInsets.top)
                .frame(maxWidth: .infinity)
                .ignoresSafeArea(edges: .top)
        }
        .frame(height: 0)
    }
}


#Preview {
    NavigationStack { HomeView() }
}

