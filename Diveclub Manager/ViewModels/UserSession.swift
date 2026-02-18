import Foundation

final class UserSession {
    static let shared = UserSession()
    private init() {}

    // TODO: Replace with your real authenticated member id source
    // This can be wired to your login/auth flow.
    var memberId: Int? = nil
}
