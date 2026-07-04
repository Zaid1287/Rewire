import SwiftUI

/// Thin green progress bar pinned near the top of quiz/report flows.
struct QuizProgressBar: View {
    var value: Double   // 0…1
    var body: some View {
        ProgressBarView(value: value, height: 8)
            .screenPadding()
    }
}
