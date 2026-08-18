import SwiftUI

/// Static content transcribed from the screenshots. Kept in one place so screens
/// stay declarative and copy is easy to audit against the source images.
enum SampleData {

    // MARK: Onboarding quiz (IMG_5428–5431)
    static let quizQuestions: [QuizQuestion] = [
        QuizQuestion(prompt: "When did you start watching porn?",
                     options: ["13 or younger", "14 to 17", "18 to 24", "25 to 32", "33 or older"]),
        QuizQuestion(prompt: "How often do you watch porn?",
                     options: ["More than once a day", "Once a day", "A few times a week",
                               "Less than once a week", "Once a month"]),
        QuizQuestion(prompt: "When was your first sexual experience?",
                     options: ["I haven't had sex yet", "24 or older", "21 to 23",
                               "18 to 20", "17 or younger"]),
        QuizQuestion(prompt: "Do you watch porn when you feel bored?",
                     options: ["Frequently", "Sometimes", "Rarely or never"])
    ]

    // MARK: Comparison (IMG_5434)
    static let withoutPoints: [ComparisonPoint] = [
        .init(text: "Get stuck in a relapse loop"),
        .init(text: "Waste a lot of time"),
        .init(text: "Feel tired every day"),
        .init(text: "Lose money, stay poor"),
        .init(text: "Ruin your life")
    ]
    static let withPoints: [ComparisonPoint] = [
        .init(text: "Quit porn addiction forever"),
        .init(text: "Reach your goals faster"),
        .init(text: "Level up in every part of life"),
        .init(text: "Be unstoppable, feel confident"),
        .init(text: "Enjoy your life")
    ]

    // MARK: Benefits — what recovery actually gives you (onboarding)
    // Glyphs match the produced asset board ("10 custom pastel glyphs"): crisp
    // vector SF Symbols on pastel circles, saturated tint from the same family.
    static let benefits: [Benefit] = [
        Benefit(symbol: "bolt.fill", isEmoji: false, iconTint: Theme.Colors.greenDark,
                iconBackground: Theme.Colors.pastelGreen, title: "Boosted energy levels",
                subtitle: "Maximize your energy every single day."),
        Benefit(symbol: "star.fill", isEmoji: false, iconTint: Color(hex: 0xC79A2E),
                iconBackground: Theme.Colors.pastelTan, title: "Improved confidence",
                subtitle: "Show your confidence in every situation."),
        Benefit(symbol: "face.smiling.fill", isEmoji: false, iconTint: Color(hex: 0xD1668A),
                iconBackground: Theme.Colors.pastelPink, title: "Better appearance",
                subtitle: "Enjoy clear skin and a healthier look."),
        Benefit(symbol: "lightbulb.fill", isEmoji: false, iconTint: Color(hex: 0xD9A72E),
                iconBackground: Theme.Colors.pastelAmber, title: "Clearer mind",
                subtitle: "Think sharper and stay focused all day."),
        Benefit(symbol: "heart.fill", isEmoji: false, iconTint: Color(hex: 0xE0555F),
                iconBackground: Theme.Colors.pastelRose, title: "Healthier libido",
                subtitle: "Rebuild a natural, present sex drive."),
        Benefit(symbol: "moon.fill", isEmoji: false, iconTint: Color(hex: 0x6A5AE0),
                iconBackground: Theme.Colors.pastelLav, title: "Deeper sleep",
                subtitle: "Sleep deeply, wake up fully recharged."),
        Benefit(symbol: "airplane.departure", isEmoji: false, iconTint: Color(hex: 0x6A5AE0),
                iconBackground: Theme.Colors.pastelLav, title: "PIED recovery",
                subtitle: "Recover from porn-induced erectile dysfunction.")
    ]

    // MARK: Relapse reasons (IMG_5445)
    static let relapseReasons = ["Boredom", "Stress", "Feeling alone", "Not being busy",
                                 "Nude photos", "Feeling horny", "Other reasons"]

    // Slip Log chip options (flow-redesign Phase 2). Single-select per group;
    // `timeOfDay` feeds the pattern insight ("3 of your last 4 slips were …").
    static let slipTimesOfDay = ["Morning", "Afternoon", "Evening", "Late night"]
    static let slipTriggers   = ["Stress", "Boredom", "Social media", "Loneliness",
                                 "Feeling horny", "Other"]
    static let slipFeelings   = ["Anxious", "Tired", "Numb", "Lonely", "Stressed"]

    // MARK: Set-goal options (IMG_5442)
    static let goals: [Goal] = {
        var g: [Goal] = [
            Goal(label: "2 hours", seconds: 2 * 3600),
            Goal(label: "4 hours", seconds: 4 * 3600),
            Goal(label: "8 hours", seconds: 8 * 3600),
            Goal(label: "12 hours", seconds: 12 * 3600),
            Goal(label: "16 hours", seconds: 16 * 3600)
        ]
        for d in 1...30 {
            g.append(Goal(label: "\(d) day\(d == 1 ? "" : "s")", seconds: TimeInterval(d) * 86_400))
        }
        return g
    }()

    // MARK: Quit Porn feature hub (IMG_5458/5459)
    static let toolkitRecommended: [FeatureItem] = [
        FeatureItem(symbol: "shield.righthalf.filled", title: "Power up your shield",
                    subtitle: "Level up your shield and keep your streak unbreakable."),
        FeatureItem(symbol: "21.circle", title: "21-day Personal Plan",
                    subtitle: "Overcome your addiction by following your personal plan.")
    ]
    static let toolkitBoost: [FeatureItem] = [
        FeatureItem(symbol: "checkmark.shield.fill", title: "Porn Blocker",
                    subtitle: "Block porn apps and websites. Avoid unexpected relapses."),
        FeatureItem(symbol: "lungs.fill", title: "Breathing Exercise",
                    subtitle: "Do your daily breathing exercises.")
    ]
    static let toolkitWillpower: [FeatureItem] = [
        FeatureItem(symbol: "rosette", title: "Challenges",
                    subtitle: "Join weekly and monthly challenges. Track your success."),
        FeatureItem(symbol: "bolt.fill", title: "My Motivations",
                    subtitle: "Never forget why you want to quit your addiction."),
        FeatureItem(symbol: "camera.fill", title: "Appearance Tracker",
                    subtitle: "Take your photo every day and track your appearance.")
    ]

    // MARK: Recovery "make streaks easier" (IMG_5460)
    static let recoveryEasier: [FeatureItem] = [
        FeatureItem(symbol: "sparkles", title: "Slip Patterns",
                    subtitle: "Every slip you log builds your pattern insight. No penalties.",
                    badge: .popular, showsChevron: false)
    ]

    // MARK: Badges (IMG_5463/5464)
    static let claimableBadges: [Badge] = [
        Badge(title: "Daily Reporter", requirement: "You must save your daily report.", state: .claimable),
        Badge(title: "Determined", requirement: "You started to use Rewire to quit porn.", state: .claimable)
    ]
    static let lockedBadges: [Badge] = [
        Badge(title: "Goal Setter", requirement: "You must set your new goal.", state: .locked),
        Badge(title: "Panic Breaker", requirement: "You must use the Panic Button.", state: .locked),
        Badge(title: "Content Blocker", requirement: "You must enable the porn blocker.", state: .locked),
        Badge(title: "Streak Guard", requirement: "You must enable notifications.", state: .locked),
        Badge(title: "Breathing Champ", requirement: "You must do a breathing exercise.", state: .locked),
        Badge(title: "Challenger", requirement: "You must accept a challenge.", state: .locked),
        Badge(title: "Motivation Master", requirement: "You must add your motivation.", state: .locked),
        Badge(title: "Responsible", requirement: "You must log a slip honestly.", state: .locked),
        Badge(title: "Pattern Finder", requirement: "Log 3 slips and unlock your pattern insight.", state: .locked),
        Badge(title: "Loyal Member", requirement: "You must add a new event.", state: .locked),
        Badge(title: "Premium Member", requirement: "You must become a premium member.", state: .locked),
        Badge(title: "Share Supporter", requirement: "You must share Rewire with your friends.", state: .locked),
        Badge(title: "Appearance Booster", requirement: "You must take your photos for tracking.", state: .locked),
        Badge(title: "Personal Plan Level 1", requirement: "You must complete first day in your plan.", state: .locked),
        Badge(title: "Personal Plan Level 2", requirement: "You must complete 3 days in your plan.", state: .locked),
        Badge(title: "Personal Plan Level 3", requirement: "You must complete 7 days in your plan.", state: .locked)
    ]

    // MARK: Levels (IMG_5465) — earned from real clean days, never bought.
    static let levels: [Level] = [
        Level(rank: 1, name: "Newcomer", dayThreshold: 0),
        Level(rank: 2, name: "Initiate", dayThreshold: 3),
        Level(rank: 3, name: "Apprentice", dayThreshold: 7),
        Level(rank: 4, name: "Journeyman", dayThreshold: 14),
        Level(rank: 5, name: "Adept", dayThreshold: 30),
        Level(rank: 6, name: "Expert", dayThreshold: 60),
        Level(rank: 7, name: "Professional", dayThreshold: 90),
        Level(rank: 8, name: "Master", dayThreshold: 120),
        Level(rank: 9, name: "Enlightened", dayThreshold: 180),
        Level(rank: 10, name: "Sage", dayThreshold: 270),
        Level(rank: 11, name: "Guardian", dayThreshold: 365),
        Level(rank: 12, name: "Visionary", dayThreshold: 500),
        Level(rank: 13, name: "Legend", dayThreshold: 730),
        Level(rank: 14, name: "Pathfinder", dayThreshold: 1000),
        Level(rank: 15, name: "Pioneer", dayThreshold: 1500)
    ]

    /// The highest-rank level whose threshold is already reached.
    static func level(forDays days: Int) -> Level {
        levels.last { $0.dayThreshold <= days } ?? levels[0]
    }

    /// The next tier up, or nil once at the max level.
    static func nextLevel(forDays days: Int) -> Level? {
        levels.first { $0.dayThreshold > days }
    }

    // MARK: 21-day Personal Plan (Quit Porn → "21-day Personal Plan")
    static let personalPlan: [PlanDay] = [
        PlanDay(day: 1, title: "Delete your triggers", detail: "Unfollow, block, and uninstall anything that leads you back to porn."),
        PlanDay(day: 2, title: "Take a cold shower", detail: "End your shower with 30 seconds of cold water to reset your urge response."),
        PlanDay(day: 3, title: "Move your body", detail: "Get 20 minutes of exercise — a walk, a run, or a workout, anything that raises your heart rate."),
        PlanDay(day: 4, title: "Write down your why", detail: "Journal three reasons you're doing this, and keep them somewhere you'll see them."),
        PlanDay(day: 5, title: "Swap the habit", detail: "Pick your usual relapse trigger time and replace it with a walk, a call, or a book."),
        PlanDay(day: 6, title: "Reach out to someone", detail: "Tell a friend or family member you're working on this — accountability keeps you honest."),
        PlanDay(day: 7, title: "Review your first week", detail: "Look back at days 1-6 and write down what worked and what didn't."),
        PlanDay(day: 8, title: "Try the Breathing Exercise", detail: "Open Breathing Exercise in this app and use it the next time an urge hits."),
        PlanDay(day: 9, title: "Clean your space", detail: "Tidy the room where you spend the most idle time — clutter feeds bad habits."),
        PlanDay(day: 10, title: "Practice gratitude", detail: "List three things going right in your life since you started this streak."),
        PlanDay(day: 11, title: "Cold shower, round two", detail: "Repeat the cold-water finish — it gets easier and the reset still works."),
        PlanDay(day: 12, title: "Digital detox for an hour", detail: "Put your phone away for one full hour today and notice how it feels."),
        PlanDay(day: 13, title: "Get outside", detail: "Spend at least 15 minutes in daylight — sunlight helps mood and sleep."),
        PlanDay(day: 14, title: "Halfway check-in", detail: "You're two weeks in. Re-read your Day 4 journal entry and see how far you've come."),
        PlanDay(day: 15, title: "Sleep before 11pm", detail: "Late nights are prime relapse hours — get ahead of it with an earlier bedtime."),
        PlanDay(day: 16, title: "Learn something new", detail: "Spend 20 minutes on a skill or hobby that has nothing to do with a screen."),
        PlanDay(day: 17, title: "Move your body again", detail: "Another workout or long walk — momentum compounds."),
        PlanDay(day: 18, title: "Plan for your next urge", detail: "Write a one-line plan for what you'll do the moment an urge hits."),
        PlanDay(day: 19, title: "Say thank you", detail: "Message the friend from Day 6 and tell them how the last two weeks went."),
        PlanDay(day: 20, title: "Reflect on the streak", detail: "Write down the biggest change you've noticed in your energy, mood, or focus."),
        PlanDay(day: 21, title: "Celebrate day 21", detail: "You finished the plan — treat yourself to something small and set your next goal.")
    ]

    // MARK: History streaks (IMG_5466)
    static let streaks: [Streak] = [
        Streak(index: 2, duration: 60, isOngoing: true),
        Streak(index: 1, duration: 60, isOngoing: false)
    ]
}
