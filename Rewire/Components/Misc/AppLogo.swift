import SwiftUI

/// The green shield-check app mark, recreated as a vector so it scales for the
/// splash and Quit Porn header. Documented as a placeholder for the real icon.
struct AppLogo: View {
    var size: CGFloat = 120
    var body: some View {
        RoundedRectangle(cornerRadius: size * 0.24, style: .continuous)
            .fill(Theme.Colors.pastelLime)
            .frame(width: size, height: size)
            .overlay(
                Image(systemName: "checkmark.shield.fill")
                    .font(.system(size: size * 0.52, weight: .bold))
                    .foregroundStyle(Theme.Colors.greenDark)
            )
    }
}

/// Orange flame drop mark used on the Home hero and streak sheet.
struct FlameMark: View {
    var size: CGFloat = 120
    var body: some View {
        Image(systemName: "flame.fill")
            .font(.system(size: size))
            .foregroundStyle(Theme.Colors.flameGradient)
    }
}

#Preview {
    HStack(spacing: 24) {
        AppLogo()
        FlameMark(size: 100)
    }
    .padding()
    .background(Theme.Colors.background)
}
