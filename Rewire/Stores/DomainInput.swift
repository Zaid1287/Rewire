import Foundation

/// Turns whatever a user types into a bare host, or rejects it.
///
/// People paste URLs, type "WWW.Example.COM/page", or half-remember a name.
/// `WebDomain(domain:)` wants a bare host, and a wrong one fails silently —
/// the site simply keeps being blocked (or keeps being allowed) with no
/// feedback, which is the worst possible outcome for an escape valve.
enum DomainInput {
    /// nil when the input can't be a host.
    static func normalize(_ raw: String) -> String? {
        var s = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !s.isEmpty else { return nil }

        // Strip scheme, then anything from the first path/query/fragment marker.
        if let range = s.range(of: "://") { s = String(s[range.upperBound...]) }
        if let cut = s.firstIndex(where: { "/?#".contains($0) }) { s = String(s[..<cut]) }
        // Credentials and port.
        if let at = s.lastIndex(of: "@") { s = String(s[s.index(after: at)...]) }
        if let colon = s.firstIndex(of: ":") { s = String(s[..<colon]) }
        // "www." is noise: Apple matches the registrable domain, and keeping it
        // would let www.example.com and example.com disagree.
        if s.hasPrefix("www.") { s = String(s.dropFirst(4)) }
        s = s.trimmingCharacters(in: CharacterSet(charactersIn: "."))

        // Must look like host.tld, with a plausible TLD and legal host characters.
        guard s.contains("."),
              !s.hasPrefix("."), !s.hasSuffix("."),
              !s.contains(".."),
              s.count <= 253,
              let tld = s.split(separator: ".").last, tld.count >= 2,
              tld.allSatisfy({ $0.isLetter }),
              s.allSatisfy({ $0.isLetter || $0.isNumber || $0 == "." || $0 == "-" })
        else { return nil }
        return s
    }
}

#if DEBUG
extension DomainInput {
    static func selfCheck() {
        // Everything a user might realistically paste.
        precondition(normalize("example.com") == "example.com")
        precondition(normalize("  Example.COM  ") == "example.com")
        precondition(normalize("www.example.com") == "example.com")
        precondition(normalize("https://www.example.com/path?q=1#x") == "example.com")
        precondition(normalize("http://example.com:8080/") == "example.com")
        precondition(normalize("user:pw@example.com") == "example.com")
        precondition(normalize("sub.example.co.uk") == "sub.example.co.uk")
        precondition(normalize("example.com.") == "example.com")

        // Rejected — each of these would otherwise become a silently dead entry.
        precondition(normalize("") == nil)
        precondition(normalize("   ") == nil)
        precondition(normalize("example") == nil, "no TLD")
        precondition(normalize("example.") == nil)
        precondition(normalize(".com") == nil)
        precondition(normalize("exa..mple.com") == nil)
        precondition(normalize("example.c") == nil, "1-char TLD")
        precondition(normalize("example.123") == nil, "numeric TLD")
        precondition(normalize("exa mple.com") == nil, "space")
        precondition(normalize("https://") == nil)
        precondition(normalize("/path/only") == nil)
        print("DomainInput.selfCheck passed")
    }
}
#endif
