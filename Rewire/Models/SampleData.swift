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

    // MARK: Chat testimonials (IMG_5427)
    static let chatTestimonials: [ChatTestimonial] = [
        ChatTestimonial(text: " I felt free after the first 21 days.",
                        boldPrefix: "Helped me in my journey to quit porn addiction.",
                        name: "Louis", isRight: false),
        ChatTestimonial(text: "I started to enjoy my life.",
                        boldPrefix: "\"I feel that I am completely free now.\"",
                        name: "Robert", isRight: true),
        ChatTestimonial(text: "Before Rewire, my streaks lasted a maximum of 5 days. ",
                        boldPrefix: nil,
                        name: "Anonymous", isRight: false),
        ChatTestimonial(text: " Thanks to everyone in this community.",
                        boldPrefix: "\"Changed my life completely.",
                        name: "Gareth", isRight: true)
    ]

    // MARK: Quote testimonials (IMG_5436)
    static let quoteTestimonials: [QuoteTestimonial] = [
        QuoteTestimonial(title: "Massive boost in confidence 💯",
                         body: "My confidence is back, and people notice. Girls at school keep complimenting me and I'm loving it.",
                         name: "Gareth", daysClean: 55),
        QuoteTestimonial(title: "Women find reasons to touch me. It's crazy! 🔥",
                         body: "Women hold eye contact, smile, move closer, and touch me for no reason. It's crazy and proof that I've changed.",
                         name: "Eric", daysClean: 41),
        QuoteTestimonial(title: "Fully cured sexual health 🔥",
                         body: "After 30 days Rewire streak, I feel fully cured. Sex is incredible, erections stronger than ever, and my control is on another level. The sensation is unreal. Thank you so much 🙏",
                         name: "Louis", daysClean: 30),
        QuoteTestimonial(title: "My social skills are back 🤝",
                         body: "Since quitting porn, every smile feels genuine and full of life. People, especially women feel it too.",
                         name: "Robert", daysClean: 17),
        QuoteTestimonial(title: "My daily energy is unstoppable ⚡️",
                         body: "Even with 5 hours of sleep, I feel unstoppable. My lifts are heavier and my head is clear all day.",
                         name: "James", daysClean: 12)
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

    // MARK: Benefits / Superpowers (IMG_5435, 5461, 5462)
    // Glyphs match the produced asset board ("10 custom pastel glyphs"): crisp
    // vector SF Symbols on pastel circles, saturated tint from the same family.
    static let benefits: [Benefit] = [
        Benefit(symbol: "bolt.fill", isEmoji: false, iconTint: Color(hex: 0x2E7D32),
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
        Benefit(symbol: "message.fill", isEmoji: false, iconTint: Color(hex: 0x2E7D32),
                iconBackground: Theme.Colors.pastelMint, title: "More attention from women",
                subtitle: "Turn heads and attract women effortlessly."),
        Benefit(symbol: "dumbbell.fill", isEmoji: false, iconTint: Color(hex: 0x444444),
                iconBackground: Theme.Colors.pastelGray, title: "Faster muscle growth",
                subtitle: "Build strength and muscle faster than ever."),
        Benefit(symbol: "heart.fill", isEmoji: false, iconTint: Color(hex: 0xE0555F),
                iconBackground: Theme.Colors.pastelRose, title: "Better libido",
                subtitle: "Enjoy a strong and healthy sex life."),
        Benefit(symbol: "moon.fill", isEmoji: false, iconTint: Color(hex: 0x6A5AE0),
                iconBackground: Theme.Colors.pastelLav, title: "Deeper sleep",
                subtitle: "Sleep deeply, wake up fully recharged."),
        Benefit(symbol: "comb.fill", isEmoji: false, iconTint: Color(hex: 0xB5793E),
                iconBackground: Theme.Colors.pastelPeach, title: "Thicker hair",
                subtitle: "Get thicker, fuller hair that looks great."),
        Benefit(symbol: "airplane.departure", isEmoji: false, iconTint: Color(hex: 0x6A5AE0),
                iconBackground: Theme.Colors.pastelLav, title: "PIED Recovery",
                subtitle: "Recover fully from porn-induced erectile dysfunction.")
    ]

    // MARK: Relapse reasons (IMG_5445)
    static let relapseReasons = ["Boredom", "Stress", "Feeling alone", "Not being busy",
                                 "Nude photos", "Feeling horny", "Other reasons"]

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

    // MARK: Plans (IMG_5441, 5467)
    static let plans: [Plan] = [
        Plan(title: "1 month", subtitle: "A good start for you", price: "₹ 249", isPopular: false),
        Plan(title: "1 year", subtitle: "only ₹58.25/month", price: "₹ 699", isPopular: true)
    ]

    // MARK: Quit Porn feature hub (IMG_5458/5459)
    static let quitRecommended: [FeatureItem] = [
        FeatureItem(symbol: "shield.righthalf.filled", title: "Power up your shield",
                    subtitle: "Level up your shield and keep your streak unbreakable."),
        FeatureItem(symbol: "21.circle", title: "21-day Personal Plan",
                    subtitle: "Overcome your addiction by following your personal plan.")
    ]
    static let quitBoost: [FeatureItem] = [
        FeatureItem(symbol: "checkmark.shield.fill", title: "Porn Blocker",
                    subtitle: "Block porn websites. Avoid unexpected relapses.", badge: .popular),
        FeatureItem(symbol: "person.2.fill", title: "Rewire Community",
                    subtitle: "Join the private Telegram group. Get amazing support."),
        FeatureItem(symbol: "app.badge", title: "Reminder Notifications",
                    subtitle: "Set your daily reminders to easily keep your streak.", warning: true),
        FeatureItem(symbol: "bubble.left.and.bubble.right.fill", title: "Private Support",
                    subtitle: "Get private support from the mentors.", badge: .popular),
        FeatureItem(symbol: "lungs.fill", title: "Breathing Exercise",
                    subtitle: "Do your daily breathing exercises.")
    ]
    static let quitWillpower: [FeatureItem] = [
        FeatureItem(symbol: "rosette", title: "Challenges",
                    subtitle: "Join weekly and monthly challenges. Track your success."),
        FeatureItem(symbol: "bolt.fill", title: "My Motivations",
                    subtitle: "Never forget why you want to quit your addiction."),
        FeatureItem(symbol: "camera.fill", title: "Appearance Tracker",
                    subtitle: "Take your photo every day and track your appearance.")
    ]
    static let quitPrivacy: [FeatureItem] = [
        FeatureItem(symbol: "faceid", title: "Login via Face ID",
                    subtitle: "Use Face ID to unlock this app."),
        FeatureItem(symbol: "applewatch", title: "Sync with your Apple Watch",
                    subtitle: "Track your streaks on your watch."),
        FeatureItem(symbol: "arrow.counterclockwise.circle", title: "Data Backup",
                    subtitle: "Backup your data or restore it easily.")
    ]

    // MARK: Recovery "make streaks easier" (IMG_5460)
    static let recoveryEasier: [FeatureItem] = [
        FeatureItem(symbol: "arrow.down.circle", title: "Relapse Penalty",
                    subtitle: "Relapsing will cost you 500 coins. Keep your streak alive! 🔥",
                    badge: .popular),
        FeatureItem(symbol: "play.circle", title: "Must-Watch Videos",
                    subtitle: "Watch the playlists that we curated the best video content for you.")
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
        Badge(title: "Community Member", requirement: "You must join the Rewire Community.", state: .locked),
        Badge(title: "Streak Guard", requirement: "You must enable notifications.", state: .locked),
        Badge(title: "Mentor Owner", requirement: "You must get private support.", state: .locked),
        Badge(title: "Breathing Champ", requirement: "You must do a breathing exercise.", state: .locked),
        Badge(title: "Challenger", requirement: "You must accept a challenge.", state: .locked),
        Badge(title: "Motivation Master", requirement: "You must add your motivation.", state: .locked),
        Badge(title: "Responsible", requirement: "You must enable relapse penalty.", state: .locked),
        Badge(title: "Penalty Locker", requirement: "You must lock your relapse penalty.", state: .locked),
        Badge(title: "Researcher", requirement: "You must unlock a video playlist.", state: .locked),
        Badge(title: "Loyal Member", requirement: "You must add a new event.", state: .locked),
        Badge(title: "Feedback Master", requirement: "You must give feedback.", state: .locked),
        Badge(title: "Rewire Supporter", requirement: "You must write a review for Rewire.", state: .locked),
        Badge(title: "Premium Member", requirement: "You must become a premium member.", state: .locked),
        Badge(title: "Share Supporter", requirement: "You must share Rewire with your friends.", state: .locked),
        Badge(title: "Appearance Booster", requirement: "You must take your photos for tracking.", state: .locked),
        Badge(title: "Personal Plan Level 1", requirement: "You must complete first day in your plan.", state: .locked),
        Badge(title: "Personal Plan Level 2", requirement: "You must complete 3 days in your plan.", state: .locked),
        Badge(title: "Personal Plan Level 3", requirement: "You must complete 7 days in your plan.", state: .locked)
    ]

    // MARK: Levels (IMG_5465)
    static let levels: [Level] = [
        Level(rank: 1, name: "Newcomer", gemCost: nil, isCurrent: true),
        Level(rank: 2, name: "Initiate", gemCost: 750, isCurrent: false),
        Level(rank: 3, name: "Apprentice", gemCost: 1000, isCurrent: false),
        Level(rank: 4, name: "Journeyman", gemCost: 1250, isCurrent: false),
        Level(rank: 5, name: "Adept", gemCost: 1500, isCurrent: false),
        Level(rank: 6, name: "Expert", gemCost: 2000, isCurrent: false),
        Level(rank: 7, name: "Professional", gemCost: 3000, isCurrent: false),
        Level(rank: 8, name: "Master", gemCost: 4000, isCurrent: false),
        Level(rank: 9, name: "Enlightened", gemCost: 5000, isCurrent: false),
        Level(rank: 10, name: "Sage", gemCost: 7500, isCurrent: false),
        Level(rank: 11, name: "Guardian", gemCost: 10000, isCurrent: false),
        Level(rank: 12, name: "Visionary", gemCost: 15000, isCurrent: false),
        Level(rank: 13, name: "Legend", gemCost: 17500, isCurrent: false),
        Level(rank: 14, name: "Pathfinder", gemCost: 20000, isCurrent: false),
        Level(rank: 15, name: "Pioneer", gemCost: 22500, isCurrent: false)
    ]

    // MARK: Weekly challenge (IMG_5457)
    static let challengeDays: [ChallengeDay] = [
        ChallengeDay(number: 1, dateLabel: "Sunday, Jun 28", state: .pending),
        ChallengeDay(number: 2, dateLabel: "Monday, Jun 29", state: .pending),
        ChallengeDay(number: 3, dateLabel: "Tuesday, Jun 30", state: .pending),
        ChallengeDay(number: 4, dateLabel: "Wednesday, Jul 1", state: .pending),
        ChallengeDay(number: 5, dateLabel: "Thursday, Jul 2", state: .pending),
        ChallengeDay(number: 6, dateLabel: "Friday, Jul 3", state: .failed),
        ChallengeDay(number: 7, dateLabel: "Saturday, Jul 4", state: .pending)
    ]

    // MARK: History streaks (IMG_5466)
    static let streaks: [Streak] = [
        Streak(index: 2, duration: 60, isOngoing: true),
        Streak(index: 1, duration: 60, isOngoing: false)
    ]
}
