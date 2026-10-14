# Native Login with Passkeys — iOS

A sample iOS app demonstrating passkey signup, login, and logout using [Auth0's Native Login](https://auth0.com/docs/authenticate/database-connections/passkeys/native-passkeys-for-mobile-applications) and the [Auth0.swift](https://github.com/auth0/Auth0.swift) SDK.

⚠️ This project is intended for demonstration purposes only and is not meant for production use. ⚠️


## Prerequisites

- **Xcode 16+**
- **iOS 16.6+** device (passkeys require a physical device or a simulator with iCloud Keychain)
- **Apple Developer account** (for Associated Domains capability)
- **Auth0 account** with a [Native Application](https://auth0.com/docs/get-started/applications)

## Setup

### 1. Create the Xcode Project

1. Open Xcode and create a new project: **App** template
2. Set **Interface** to SwiftUI, **Language** to Swift
3. Name the project `NativePasskeys`
4. Copy the Swift source files from this repo into the project

### 2. Add the Auth0.swift SDK

1. In Xcode, go to **File > Add Package Dependencies**
2. Enter: `https://github.com/auth0/Auth0.swift`
3. Set the version to **2.12.0** or later
4. Add the `Auth0` and `JWTDecode` libraries to your target

### 3. Configure Auth0

1. Update `Auth0.plist` with your Auth0 **Client ID** and **custom domain**
2. In the Auth0 Dashboard:
   - Enable passkeys on your database connection
   - Enable the **Passkey** grant type on your application (Advanced Settings > Grant Types)
   - Add your **Team ID** and **Bundle Identifier** under Device Settings (Advanced Settings > Device Settings > iOS)
   - Set up a [custom domain](https://auth0.com/docs/customize/custom-domains)
   - Setting up the callbacks in the app --> https://YOUR_AUTH0_DOMAIN/ios/YOUR_BUNDLE_IDENTIFIER/callback,YOUR_BUNDLE_IDENTIFIER://YOUR_AUTH0_DOMAIN/ios/YOUR_BUNDLE_IDENTIFIER/callback <-- in this case the HTTPS:// is the important one, and needs to have the custom domain.

### 4. Configure Associated Domains

1. In Xcode, select your target > **Signing & Capabilities**
2. Add the **Associated Domains** capability
3. Add: `webcredentials:YOUR_AUTH0_CUSTOM_DOMAIN`

Or update `NativePasskeys.entitlements` directly with your custom domain.

### 5. Run

Build and run on a physical iOS device (or a simulator with iCloud Keychain configured).

## Project Structure

```
NativePasskeys/
├── NativePasskeysApp.swift      # App entry point, root navigation
├── LoginView.swift              # Email field, Login and Sign Up buttons
├── HomeView.swift               # User greeting, ID token display, Logout
├── AuthViewModel.swift          # Passkey auth logic + ASAuthorization delegate
├── Auth0.plist                  # Auth0 Client ID and domain
└── NativePasskeys.entitlements  # Associated Domains
```

## How It Works

Both signup and login follow a three-step flow:

1. **Challenge** — The app requests a WebAuthn challenge from Auth0 (`/passkey/register` for signup, `/passkey/challenge` for login)
2. **Credential** — Apple's `ASAuthorizationController` creates or retrieves a passkey on-device
3. **Token exchange** — The app sends the credential back to Auth0 (`/oauth/token`) and receives access, ID, and refresh tokens

The Auth0.swift SDK handles the API calls. Apple's `ASAuthorizationPlatformPublicKeyCredentialRegistration` and `ASAuthorizationPlatformPublicKeyCredentialAssertion` types conform directly to the SDK's `SignupPasskey` and `LoginPasskey` protocols — no manual JSON serialization required.

## License

Copyright 2026 Okta, Inc. [Licensed under the Apache License, Version 2.0](LICENSE.txt) (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at: http://www.apache.org/licenses/LICENSE-2.0
