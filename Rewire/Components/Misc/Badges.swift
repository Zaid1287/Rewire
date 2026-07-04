import SwiftUI

/// Small "POPULAR" (indigo) / "PLUS" (green) pill tags.
struct TagBadge: View {
    enum Kind { case popular, plus
        var text: String { self == .popular ? "POPULAR" : "PLUS" }
        var color: Color { self == .popular ? Theme.Colors.primary : Color(hex: 0x2E7D32) }
    }
    let kind: Kind

    var body: some View {
        Text(kind.text)
            .font(.system(size: 11, weight: .bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(kind.color, in: RoundedRectangle(cornerRadius: Theme.Radius.xs))
    }
}

/// Red count bubble ("1") used on tab icons and Daily Report.
struct CountBadge: View {
    let count: Int
    var body: some View {
        Text("\(count)")
            .font(.system(size: 12, weight: .bold))
            .foregroundStyle(.white)
            .frame(minWidth: 20, minHeight: 20)
            .padding(.horizontal, 2)
            .background(Theme.Colors.red, in: Circle())
    }
}

/// Small warning octagon/dot after a title (Reminder Notifications, times watched).
struct WarningDot: View {
    var body: some View {
        Image(systemName: "exclamationmark.octagon.fill")
            .font(.system(size: 18))
            .foregroundStyle(Theme.Colors.flame)
    }
}

#Preview {
    HStack(spacing: 12) {
        TagBadge(kind: .popular)
        TagBadge(kind: .plus)
        CountBadge(count: 1)
        WarningDot()
    }
    .padding()
    .background(Theme.Colors.background)
}
