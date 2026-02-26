//
//  AppSettingsManager.swift
//  DiveclubApp
//
//  Created by Eckhard Becker on 07.02.26.
//
import SwiftUI
import Combine

@MainActor
final class AppSettingsManager: ObservableObject {

    static let shared = AppSettingsManager()

    @Published var timeout: TimeInterval
    @Published var baseURL: String

    // ✅ Remote App Config
    @Published private(set) var appConfig: AppConfigDTO?
    @Published private(set) var isLoadingConfig: Bool = false
    @Published private(set) var configError: String? = nil

    // Cache-Keys
    private let cacheImprintKey = "cache_imprint_html"
    private let cachePrivacyKey = "cache_privacy_html"
    private let cacheTermsKey   = "cache_terms_html"

    private init() {
        let storedTimeout = UserDefaults.standard.double(forKey: "appTimeout")
        self.timeout = storedTimeout == 0 ? 120 : storedTimeout

        self.baseURL = UserDefaults.standard.string(forKey: "baseURL")
            ?? "https://contao56.ddev.site"
    }

    // MARK: - Persistenz

    func updateTimeout(_ value: TimeInterval) {
        timeout = value
        UserDefaults.standard.set(value, forKey: "appTimeout")
    }

    func updateBaseURL(_ value: String) {
        let v = value.trimmingCharacters(in: .whitespacesAndNewlines)
        baseURL = v
        UserDefaults.standard.set(v, forKey: "baseURL")
    }

    // MARK: - Validierung

    func isValidURL(_ string: String) -> Bool {
        let s = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: s),
              url.scheme == "https",
              url.host != nil else {
            return false
        }
        return true
    }

    // MARK: - App Info

    var appVersionString: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
        return "\(v) (\(b))"
    }

    // MARK: - Rechtliches (✅ Remote + Fallback Cache)

    var imprintHTML: String {
        if let html = appConfig?.imprint, !html.isEmpty { return html }
        return UserDefaults.standard.string(forKey: cacheImprintKey) ?? ""
    }

    var privacyHTML: String {
        if let html = appConfig?.privacy, !html.isEmpty { return html }
        return UserDefaults.standard.string(forKey: cachePrivacyKey) ?? ""
    }

    var termsHTML: String {
        if let html = appConfig?.terms, !html.isEmpty { return html }
        return UserDefaults.standard.string(forKey: cacheTermsKey) ?? ""
    }

    /// Lädt /api/app/config und cached Rechtstexte
    func reloadRemoteConfig() async {
        guard isValidURL(baseURL) else { return }

        isLoadingConfig = true
        configError = nil
        defer { isLoadingConfig = false }

        do {
            let cfg: AppConfigDTO = try await APIClient.shared.request("app/config")
            appConfig = cfg

            // Cache nur die Rechtstexte
            if let s = cfg.imprint { UserDefaults.standard.set(s, forKey: cacheImprintKey) }
            if let s = cfg.privacy { UserDefaults.standard.set(s, forKey: cachePrivacyKey) }
            if let s = cfg.terms { UserDefaults.standard.set(s, forKey: cacheTermsKey) }

        } catch {
            configError = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            // appConfig bleibt ggf. alt; Fallback über Cache-Properties
        }
    }
}
