import SwiftUI

/// UPPERCASE tracked section label with an optional trailing action link.
struct SectionHeader<Trailing: View>: View {
    let title: String
    @ViewBuilder var trailing: Trailing

    var body: some View {
        HStack {
            Text(title).sectionHeaderStyle()
            Spacer()
            trailing
        }
    }
}

extension SectionHeader where Trailing == EmptyView {
    init(_ title: String) {
        self.init(title: title) { EmptyView() }
    }
}

#Preview {
    VStack(spacing: 20) {
        SectionHeader("Shortcuts")
        SectionHeader(title: "Progress") {
            LinkButton(title: "Set Goal") {}
        }
    }
    .padding()
    .background(Theme.Colors.background)
}
