import AuthenticationServices
import Auth0
import JWTDecode
import Combine

@MainActor
class AuthViewModel: NSObject, ObservableObject {

    // MARK: - Published Properties

    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var error: String?
    @Published var userName = ""
    @Published var idToken = ""

    // MARK: - Private Properties

    private let authentication = Auth0.authentication()
    private let credentialsManager: CredentialsManager
    private let connection = "Username-Password-Authentication"
    private var authorizationContinuation: CheckedContinuation<ASAuthorizationCredential, Error>?

    // MARK: - Initialization

    override init() {
        self.credentialsManager = CredentialsManager(authentication: Auth0.authentication())
        super.init()
        self.isAuthenticated = credentialsManager.hasValid()
    }

    // MARK: - Sign Up with Passkey

    func signUpWithPasskey(email: String) async {
        isLoading = true
        error = nil

        do {
            // 1. Request a signup challenge from Auth0
            let challenge = try await authentication
                .passkeySignupChallenge(email: email, connection: connection)
                .start()

            // 2. Create a new passkey using Apple's ASAuthorization API
            let provider = ASAuthorizationPlatformPublicKeyCredentialProvider(
                relyingPartyIdentifier: challenge.relyingPartyId
            )
            let registrationRequest = provider.createCredentialRegistrationRequest(
                challenge: challenge.challengeData,
                name: challenge.userName,
                userID: challenge.userId
            )
            let credential = try await performAuthorizationRequest(registrationRequest)

            guard let registration = credential
                    as? ASAuthorizationPlatformPublicKeyCredentialRegistration else {
                throw PasskeyError.unexpectedCredentialType
            }

            // 3. Complete signup by exchanging the passkey for Auth0 tokens
            let credentials = try await authentication
                .login(passkey: registration, challenge: challenge, connection: connection)
                .start()

            _ = credentialsManager.store(credentials: credentials)
            isAuthenticated = true
        } catch ASAuthorizationError.canceled {
            // User cancelled the passkey prompt — no error to show
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    // MARK: - Login with Passkey

    func loginWithPasskey() async {
        isLoading = true
        error = nil

        do {
            // 1. Request a login challenge from Auth0
            let challenge = try await authentication
                .passkeyLoginChallenge(connection: connection)
                .start()

            // 2. Retrieve an existing passkey using Apple's ASAuthorization API
            let provider = ASAuthorizationPlatformPublicKeyCredentialProvider(
                relyingPartyIdentifier: challenge.relyingPartyId
            )
            let assertionRequest = provider.createCredentialAssertionRequest(
                challenge: challenge.challengeData
            )
            let credential = try await performAuthorizationRequest(assertionRequest)

            guard let assertion = credential
                    as? ASAuthorizationPlatformPublicKeyCredentialAssertion else {
                throw PasskeyError.unexpectedCredentialType
            }

            // 3. Complete login by exchanging the passkey for Auth0 tokens
            let credentials = try await authentication
                .login(passkey: assertion, challenge: challenge, connection: connection)
                .start()

            _ = credentialsManager.store(credentials: credentials)
            isAuthenticated = true
        } catch ASAuthorizationError.canceled {
            // User cancelled the passkey prompt — no error to show
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    // MARK: - Load User Profile

    func loadUserProfile() async {
        do {
            let credentials = try await credentialsManager.credentials()
            idToken = credentials.idToken
            let jwt = try decode(jwt: credentials.idToken)
            userName = jwt["name"].string ?? jwt["email"].string ?? "User"
        } catch {
            self.error = error.localizedDescription
            isAuthenticated = false
        }
    }

    // MARK: - Logout

    func logout() {
        _ = credentialsManager.clear()
        isAuthenticated = false
        userName = ""
        idToken = ""
    }

    // MARK: - ASAuthorization Bridging

    private func performAuthorizationRequest(
        _ request: ASAuthorizationRequest
    ) async throws -> ASAuthorizationCredential {
        try await withCheckedThrowingContinuation { continuation in
            self.authorizationContinuation = continuation
            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self
            controller.performRequests()
        }
    }
}

// MARK: - ASAuthorizationControllerDelegate

extension AuthViewModel: ASAuthorizationControllerDelegate {

    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        authorizationContinuation?.resume(returning: authorization.credential)
        authorizationContinuation = nil
    }

    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        authorizationContinuation?.resume(throwing: error)
        authorizationContinuation = nil
    }
}

// MARK: - ASAuthorizationControllerPresentationContextProviding

extension AuthViewModel: ASAuthorizationControllerPresentationContextProviding {

    func presentationAnchor(
        for controller: ASAuthorizationController
    ) -> ASPresentationAnchor {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow } ?? ASPresentationAnchor()
    }
}

// MARK: - Errors

enum PasskeyError: LocalizedError {
    case unexpectedCredentialType

    var errorDescription: String? {
        switch self {
        case .unexpectedCredentialType:
            return "Received an unexpected credential type."
        }
    }
}
