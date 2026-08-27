import SwiftUI

/// Top-level app phase — gates onboarding vs. the main tab bar.
@Observable
final class AppState {
    enum Phase: String, Codable { case onboarding, main }
    var phase: Phase = .onboarding { didSet { persist?() } }

    /// Currently selected main tab. In debug builds `REWIRE_TAB=<rawValue>` in
    /// the environment lands the app on a given tab — lets a screenshot pass
    /// reach any tab without driving the UI.
    var selectedTab: Tab = {
        #if DEBUG
        if let raw = ProcessInfo.processInfo.environment["REWIRE_TAB"],
           let value = Int(raw), let tab = Tab(rawValue: value) { return tab }
        #endif
        return .today
    }()

    /// Appearance preference (Settings → Appearance). Dark is the default —
    /// the app's designed-first mode and what existing installs expect.
    enum Appearance: String, Codable, CaseIterable {
        case system, light, dark
        var title: String { rawValue.capitalized }
        /// nil = follow the system setting.
        var colorScheme: ColorScheme? {
            switch self {
            case .system: nil
            case .light: .light
            case .dark: .dark
            }
        }
    }
    private(set) var appearance: Appearance = .dark { didSet { persist?() } }

    func setAppearance(_ a: Appearance) {
        appearance = a
    }

    /// Whether the dock is folded to its icon pill. Runtime-only, never
    /// persisted — driven by scroll direction (down folds, up opens) via
    /// `collapsesDock()` on each tab's ScrollView, and by tapping the pill.
    var dockCollapsed: Bool = false

    /// Onboarding quiz answers — one option index per question.
    private(set) var quizAnswers: [Int] = [] { didSet { persist?() } }

    /// Personal "why I quit" notes (Quit Porn → My Motivations), newest first.
    private(set) var motivations: [Motivation] = [] { didSet { persist?() } }

    /// Daily photo journal (Quit Porn → Appearance Tracker), newest first.
    /// Images live at Documents/appearance/<filename>; only the entries are
    /// persisted in the snapshot.
    private(set) var appearancePhotos: [AppearancePhoto] = [] { didSet { persist?() } }

    /// Daily reminder settings (Quit Porn → Reminder Notifications). The
    /// actual `UNUserNotificationCenter` scheduling happens in the view layer
    /// (ReminderScheduler) — this store is just the persisted data holder.
    private(set) var reminderEnabled: Bool = false { didSet { persist?() } }

    /// Analytics consent. **Default off, and it stays off until the user turns
    /// it on** — this app holds special-category health data, so nothing is
    /// sent on an assumption. Read by `Analytics.start(optedIn:)`.
    private(set) var analyticsOptIn: Bool = false { didSet { persist?() } }

    /// iCloud backup consent. Default off: the data is special-category, and
    /// even "your own iCloud" is still off the device, so it's the user's call.
    private(set) var cloudSyncOptIn: Bool = false { didSet { persist?() } }

    func setCloudSyncOptIn(_ on: Bool) { cloudSyncOptIn = on }

    func setAnalyticsOptIn(_ on: Bool) {
        analyticsOptIn = on
        Analytics.start(optedIn: on)
    }
    private(set) var reminderHour: Int = 21 { didSet { persist?() } }
    private(set) var reminderMinute: Int = 0 { didSet { persist?() } }

    /// Face ID app-lock (Quit Porn → Privacy). Persisted.
    private(set) var faceIDEnabled: Bool = false { didSet { persist?() } }

    /// Whether the lock screen is currently dismissed. Runtime-only — never
    /// persisted, always starts `true` so enabling Face ID doesn't immediately
    /// re-lock the same launch. RootView flips it to `false` on backgrounding.
    var isUnlocked: Bool = true

    /// Saver injected by RewireApp so mutations flush to disk.
    var persist: (() -> Void)?

    /// 4-tab IA (flow-redesign Phase 4, plan §1): Today / Progress / Toolkit /
    /// Settings. Progress merges the old Recovery + History ("how am I doing?"
    /// is one mental model); Toolkit is the old Quit Porn hub minus the rows
    /// that were really settings. Direct labels over vague ones ("Home").
    enum Tab: Int, CaseIterable {
        case today, progress, toolkit, settings
        var title: String {
            switch self {
            case .today: "Today"
            case .progress: "Recovery"
            case .toolkit: "Toolkit"
            case .settings: "Settings"
            }
        }
        var symbol: String {
            switch self {
            case .today: "house"
            case .progress: "leaf"
            case .toolkit: "wrench.and.screwdriver"
            case .settings: "gearshape"
            }
        }
        var activeSymbol: String {
            switch self {
            case .today: "house.fill"
            case .progress: "leaf.fill"
            case .toolkit: "wrench.and.screwdriver.fill"
            case .settings: "gearshape.fill"
            }
        }
        /// Static fallback badge — live unclaimed-badge count overrides this.
        var badgeCount: Int? { nil }
    }

    func finishOnboarding() {
        withAnimation(Theme.Motion.standard) { phase = .main }
    }

    /// Record (or overwrite) the chosen option for a quiz question.
    func recordAnswer(questionIndex: Int, optionIndex: Int) {
        guard questionIndex >= 0 else { return }
        if quizAnswers.count <= questionIndex {
            quizAnswers += Array(repeating: 0, count: questionIndex - quizAnswers.count + 1)
        }
        quizAnswers[questionIndex] = optionIndex
    }

    /// Adds a trimmed, non-empty motivation to the top of the list.
    func addMotivation(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        motivations.insert(Motivation(text: trimmed), at: 0)
    }

    func deleteMotivation(_ m: Motivation) {
        motivations.removeAll { $0.id == m.id }
    }

    /// Directory the appearance photos are stored in, created on first use.
    private static var appearanceDir: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = docs.appendingPathComponent("appearance", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    /// Full file URL for a stored appearance photo's filename.
    static func appearancePhotoURL(_ filename: String) -> URL {
        appearanceDir.appendingPathComponent(filename)
    }

    /// Saves `image` as a new appearance-photo entry, newest first.
    func addAppearancePhoto(_ image: UIImage) {
        guard let data = image.jpegData(compressionQuality: 0.7) else { return }
        let filename = "\(UUID().uuidString).jpg"
        do {
            try data.write(to: Self.appearancePhotoURL(filename),
                           options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
        } catch {
            // ponytail: best-effort local write; failure just drops this entry.
            return
        }
        appearancePhotos.insert(AppearancePhoto(filename: filename), at: 0)
    }

    func deleteAppearancePhoto(_ photo: AppearancePhoto) {
        try? FileManager.default.removeItem(at: Self.appearancePhotoURL(photo.filename))
        appearancePhotos.removeAll { $0.id == photo.id }
    }

    /// Updates the daily reminder settings. Only overwrites `hour`/`minute`
    /// when provided. Callers are responsible for the matching
    /// `ReminderScheduler` call (permission request + schedule/cancel).
    func setReminder(enabled: Bool, hour: Int? = nil, minute: Int? = nil) {
        reminderEnabled = enabled
        if let hour { reminderHour = hour }
        if let minute { reminderMinute = minute }
    }

    func setFaceIDEnabled(_ enabled: Bool) {
        faceIDEnabled = enabled
    }

    /// What the quiz can honestly say back to the user.
    ///
    /// **This replaced a 0–100 "addiction score"** that was invented three ways
    /// over: it summed answers to questions that aren't dependency signals (age
    /// of first porn, age of first sexual experience) as if they were, it treated
    /// a higher option index as "worse" even where the options don't run that way
    /// (index 0 of question 1 is "13 or younger"), and it clamped the result to
    /// 35–95 — so a user answering every question in the healthiest available way
    /// was still told they were 35% dependent. A downstream line then multiplied
    /// it by 2.5 and presented the product as "about N days of clean time before
    /// the pull fades".
    ///
    /// Invented numbers are the harshest signal in the review corpus: 1.54★
    /// average, 85% of them 1–2★ (*"Have fun with your pseudoscientific woo"*).
    /// Same reason the "% rewired" gauge was cut in #14.
    ///
    /// So this returns no number. It reflects back what the user actually told
    /// us and names the pattern in words — claims we can stand behind, because
    /// they are the user's own answers.
    struct DependencyReading {
        /// Plain-language name for the pattern. Never a diagnosis.
        let band: String
        /// What they said, quoted back — the evidence for the band.
        let reflections: [String]
        /// Forward-looking line. Encouraging, but never a timeline.
        let outlook: String
    }

    /// Index of the answer to a question, if it was answered.
    private func answer(_ index: Int) -> Int? {
        guard quizAnswers.indices.contains(index) else { return nil }
        return quizAnswers[index]
    }

    var dependencyReading: DependencyReading {
        // Only the two questions that actually describe present-day use.
        // Frequency: 0 = more than once a day … 4 = once a month.
        // Boredom:   0 = frequently, 1 = sometimes, 2 = rarely or never.
        let frequency = answer(1)
        let boredom = answer(3)

        var reflections: [String] = []
        if let frequency, SampleData.quizQuestions.indices.contains(1),
           SampleData.quizQuestions[1].options.indices.contains(frequency) {
            reflections.append("You watch \(SampleData.quizQuestions[1].options[frequency].lowercased()).")
        }
        if let boredom {
            switch boredom {
            case 0: reflections.append("Boredom is a reliable trigger for you.")
            case 1: reflections.append("Boredom sometimes leads you there.")
            default: reflections.append("Boredom isn't usually what leads you there.")
            }
        }

        // Daily use, or frequent use tightly coupled to boredom.
        let isDaily = (frequency ?? 2) <= 1
        let isCoupled = (frequency ?? 4) <= 2 && (boredom ?? 2) == 0

        if isDaily {
            return DependencyReading(
                band: "A daily habit",
                reflections: reflections,
                outlook: "Daily habits are the ones that feel hardest to interrupt — and the ones where stopping changes the most. There's no timeline here, because nobody can honestly give you one.")
        }
        if isCoupled {
            return DependencyReading(
                band: "A habit with a trigger",
                reflections: reflections,
                outlook: "You've already named the thing that sets it off, which is most of the work. The app's job now is to be there at that moment.")
        }
        return DependencyReading(
            band: "An occasional habit",
            reflections: reflections,
            outlook: "Occasional doesn't mean easy — it means you're starting from a good place. The tools work the same either way.")
    }

    // MARK: Persistence

    func restore(from s: AppSnapshot) {
        phase = s.phase
        quizAnswers = s.quizAnswers
        motivations = s.motivations ?? []
        appearancePhotos = s.appearancePhotos ?? []
        reminderEnabled = s.reminderEnabled ?? false
        analyticsOptIn = s.analyticsOptIn ?? false
        cloudSyncOptIn = s.cloudSyncOptIn ?? false
        reminderHour = s.reminderHour ?? 21
        reminderMinute = s.reminderMinute ?? 0
        faceIDEnabled = s.faceIDEnabled ?? false
        appearance = s.appearance ?? .dark
        // Cold launches must start locked when the lock is on — isUnlocked
        // defaults true for the no-lock case, so without this a force-kill +
        // relaunch would bypass Face ID entirely.
        isUnlocked = !faceIDEnabled
    }
}
