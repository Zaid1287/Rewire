import SwiftUI

/// Vector treasure chest on a gold disc — matches the produced `reward_chest`
/// asset. Replaces the earlier toolbox emoji on the reward-box screen.
struct ChestMark: View {
    var size: CGFloat = 140
    var onGold: Bool = true

    var body: some View {
        ZStack {
            if onGold {
                Circle().fill(
                    LinearGradient(colors: [Color(hex: 0xFFC93C), Color(hex: 0xF2A81E)],
                                   startPoint: .top, endPoint: .bottom))
            }
            chest
                .frame(width: size * 0.62, height: size * 0.52)
        }
        .frame(width: size, height: size)
    }

    private var chest: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            let bandW = w * 0.13
            let lidH = h * 0.42
            ZStack {
                // Body
                RoundedRectangle(cornerRadius: w * 0.06)
                    .fill(Color(hex: 0x8A5A2B))
                    .frame(width: w, height: h * 0.64)
                    .offset(y: h * 0.18)
                // Lid
                UnevenRoundedRectangle(topLeadingRadius: w * 0.22, topTrailingRadius: w * 0.22)
                    .fill(Color(hex: 0xA06A33))
                    .frame(width: w, height: lidH)
                    .offset(y: -h * 0.22)
                // Lid rim
                RoundedRectangle(cornerRadius: w * 0.03)
                    .fill(Color(hex: 0xF2A81E))
                    .frame(width: w, height: h * 0.10)
                    .offset(y: -h * 0.03)
                // Center gold band
                Rectangle().fill(Color(hex: 0xF2A81E))
                    .frame(width: bandW, height: h)
                // Lock
                RoundedRectangle(cornerRadius: w * 0.03)
                    .fill(Color(hex: 0xFFDF7A))
                    .frame(width: bandW * 1.2, height: h * 0.16)
                    .offset(y: h * 0.02)
            }
        }
    }
}

#Preview {
    ChestMark()
        .padding()
        .background(Theme.Colors.background)
}
