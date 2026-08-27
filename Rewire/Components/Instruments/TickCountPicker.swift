import SwiftUI

/// Tick-ruler picker for a small discrete range. Stands in for the system
/// `Stepper`, which is a default control the design language rules out — and
/// which also costs four taps to cross a five-value range.
///
/// Reads as an instrument: a full-width ruler of 1px ticks, taller and butter
/// through the selected value, short and quiet past it, with the current value
/// floating above as a Thin numeral and its unit at half weight.
struct TickCountPicker: View {
    @Binding var value: Int
    var range: ClosedRange<Int>
    var unit: String

    /// Ticks per step. The in-between ticks belong to no value — they're ruler
    /// texture, which is what stops it reading as five fat buttons.
    private let subdivisions = 4

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("\(value)")
                    .font(Theme.Typography.statNumber())
                    .foregroundStyle(Theme.Colors.textHi)
                    .monospacedDigit()
                    .contentTransition(.numericText())
                Text(unit)
                    .font(Theme.Typography.caption())
                    .foregroundStyle(Theme.Colors.textXlo)
                Spacer(minLength: 0)
            }

            GeometryReader { geo in
                let steps = range.count
                let slotWidth = geo.size.width / CGFloat(steps)
                let filled = value - range.lowerBound + 1

                ZStack(alignment: .leading) {
                    Canvas { ctx, size in
                        let total = steps * subdivisions
                        for i in 0...total {
                            let x = size.width * CGFloat(i) / CGFloat(total)
                            // A tick is "major" when it lands on a value.
                            let isMajor = i % subdivisions == 0
                            let stepIndex = i / subdivisions
                            let active = stepIndex < filled
                            // Majors carry the value, minors are texture — the
                            // gap between them has to be obvious or the ruler
                            // reads as a row of identical bars.
                            let height: CGFloat = isMajor ? (active ? 22 : 13) : 5
                            var path = Path()
                            path.move(to: CGPoint(x: x, y: size.height))
                            path.addLine(to: CGPoint(x: x, y: size.height - height))
                            ctx.stroke(
                                path,
                                with: .color(active
                                             ? Theme.Colors.butter.opacity(isMajor ? 1 : 0.35)
                                             : Color.white.opacity(isMajor ? 0.28 : 0.10)),
                                lineWidth: isMajor ? 1.5 : 1)
                        }
                    }
                    .frame(height: 22)
                }
                .frame(height: 22)
                .contentShape(Rectangle())
                // Tap or drag anywhere on the ruler — the whole instrument is
                // the control, not five separate hit targets.
                .gesture(
                    DragGesture(minimumDistance: 0).onChanged { g in
                        let slot = Int(g.location.x / max(slotWidth, 1))
                        let next = min(max(range.lowerBound + slot, range.lowerBound),
                                       range.upperBound)
                        guard next != value else { return }
                        Haptics.tap()          // one detent tick per value crossed
                        withAnimation(.spring(response: 0.55, dampingFraction: 0.9)) {
                            value = next
                        }
                    }
                )
            }
            .frame(height: 22)
        }
    }
}

#Preview {
    @Previewable @State var v = 3
    return TickCountPicker(value: $v, range: 1...5, unit: "a day")
        .padding(40)
        .background { SceneBackground(kind: .void) }
}
