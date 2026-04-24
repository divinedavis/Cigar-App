import AuthenticationServices
import UIKit

/// Thin wrapper around `ASAuthorizationAppleIDProvider` so the splash screen
/// can drive Sign in with Apple from a SwiftUI button. Returns the user's
/// stable Apple identifier plus whatever display name Apple provides on the
/// first authorization (subsequent sign-ins only return the identifier).
final class AppleSignInCoordinator: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    struct Result {
        let userID: String
        let displayName: String
        let email: String?
    }

    private var onSuccess: ((Result) -> Void)?
    private var onFailure: ((Error) -> Void)?

    func start(onSuccess: @escaping (Result) -> Void,
               onFailure: @escaping (Error) -> Void) {
        self.onSuccess = onSuccess
        self.onFailure = onFailure

        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]

        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        controller.performRequests()
    }

    func authorizationController(controller: ASAuthorizationController,
                                 didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            onFailure?(NSError(domain: "AppleSignIn", code: -1))
            return
        }
        let given = credential.fullName?.givenName ?? ""
        let family = credential.fullName?.familyName ?? ""
        let combined = [given, family].filter { !$0.isEmpty }.joined(separator: " ")
        let fallback = credential.email?.components(separatedBy: "@").first ?? "friend"
        let displayName = combined.isEmpty ? fallback : combined
        onSuccess?(Result(userID: credential.user,
                          displayName: displayName,
                          email: credential.email))
    }

    func authorizationController(controller: ASAuthorizationController,
                                 didCompleteWithError error: Error) {
        onFailure?(error)
    }

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow } ?? ASPresentationAnchor()
    }
}
