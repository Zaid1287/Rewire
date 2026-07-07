import LocalAuthentication

/// Thin wrapper over `LocalAuthentication` for the Face ID app-lock feature.
/// `.deviceOwnerAuthentication` (not `...WithBiometrics`) so passcode fallback
/// is handled by the system automatically.
enum BiometricAuth {
    static var canUseBiometrics: Bool {
        LAContext().canEvaluatePolicy(.deviceOwnerAuthentication, error: nil)
    }

    static func authenticate(reason: String = "Unlock Rewire") async -> Bool {
        let context = LAContext()
        let result = try? await context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason)
        return result ?? false
    }
}
