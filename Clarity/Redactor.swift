// Redactor.swift
import Foundation

struct RedactionResult: Equatable {
    let redactedText: String
    let didRedact: Bool
}

struct Redactor {
    private let tokens: [String]

    init(tokens: [String] = []) {
        self.tokens = tokens
    }

    // MARK: - Public

    func redact(_ input: String) -> RedactionResult {
        guard !input.isEmpty else {
            return RedactionResult(redactedText: input, didRedact: false)
        }

        // 1) Collect structural PII matches on ORIGINAL input (no replacements yet).
        var candidates: [RedactionMatch] = []
        candidates.append(contentsOf: structuralMatches(in: input))

        // 2) Resolve overlaps with strong precedence rules.
        let chosenStructural = chooseNonOverlapping(candidates)

        // 3) Collect CUSTOM matches only in remaining spans.
        var allChosen = chosenStructural
        if !tokens.isEmpty {
            let custom = customMatches(in: input, excluding: chosenStructural)
            allChosen = chooseNonOverlapping(chosenStructural + custom)
        }

        // 4) Apply replacements once.
        let (out, did) = apply(matches: allChosen, to: input)
        return RedactionResult(redactedText: out, didRedact: did)
    }

    // MARK: - Match Types

    private enum Kind: Int, Comparable {
        // Higher rawValue = higher priority
        case custom    = 10

        case vat       = 20
        case utr       = 21
        case nino      = 22
        case postcode  = 23
        case sortcode  = 24
        case phone     = 25
        case account   = 26
        case cardQ     = 27
        case card      = 28
        case bic       = 29
        case iban      = 30
        case email     = 31

        var label: String {
            switch self {
            case .email:    return "[EMAIL]"
            case .phone:    return "[PHONE]"
            case .postcode: return "[POSTCODE]"
            case .iban:     return "[IBAN]"
            case .bic:      return "[BIC]"
            case .sortcode: return "[SORTCODE]"
            case .account:  return "[ACCOUNT]"
            case .card:     return "[CARD]"
            case .cardQ:    return "[CARD?]"
            case .nino:     return "[NINO]"
            case .utr:      return "[UTR]"
            case .vat:      return "[VAT]"
            case .custom:   return "[CUSTOM]"
            }
        }

        static func < (lhs: Kind, rhs: Kind) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }

    private struct RedactionMatch: Equatable {
        let range: NSRange
        let kind: Kind

        var replacement: String { kind.label }

        func overlaps(_ other: RedactionMatch) -> Bool {
            NSIntersectionRange(range, other.range).length > 0
        }
    }

    // MARK: - Structural patterns

    private func structuralMatches(in input: String) -> [RedactionMatch] {
        var out: [RedactionMatch] = []

        // EMAIL (atomic)
        out += ranges(
            input,
            pattern: #"\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}\b"#,
            options: [.caseInsensitive]
        ).map { RedactionMatch(range: $0, kind: .email) }

        // PHONE (international-ish, conservative)
        out += ranges(
            input,
            pattern: #"\b(?:\+|00)\d{1,3}[\s-]?(?:\(?\d+\)?[\s-]?){3,}\d\b"#,
            options: [.caseInsensitive]
        ).map { RedactionMatch(range: $0, kind: .phone) }

        // UK mobile (basic)
        out += ranges(
            input,
            pattern: #"\b(\+44\s?7\d{3}|\(?07\d{3}\)?)\s?\d{3}\s?\d{3}\b"#,
            options: [.caseInsensitive]
        ).map { RedactionMatch(range: $0, kind: .phone) }

        // UK postcode (basic)
        out += ranges(
            input,
            pattern: #"\b([A-Z]{1,2}\d{1,2}[A-Z]?)\s?(\d[A-Z]{2})\b"#,
            options: [.caseInsensitive]
        ).map { RedactionMatch(range: $0, kind: .postcode) }

        // IBAN (unspaced) – high confidence
        out += ranges(
            input,
            pattern: #"\b[A-Z]{2}\d{2}[A-Z0-9]{11,30}\b"#,
            options: [.caseInsensitive]
        ).map { RedactionMatch(range: $0, kind: .iban) }

        // IBAN (spaced) – tolerate transcription spaces/hyphens.
        // Require it to start like an IBAN (CCdd) and then 11+ alnum total when spaces removed.
        // Example: "GB29 NWBK 6016 1331 9268 19"
        let ibanSpaced = ranges(
            input,
            pattern: #"\b[A-Z]{2}\d{2}(?:[\s-]?[A-Z0-9]){11,40}\b"#,
            options: [.caseInsensitive]
        )
        for r in ibanSpaced {
            let snippet = substring(input, nsRange: r)
            let cleaned = snippet.filter { $0.isLetter || $0.isNumber }.uppercased()
            // Must still look like IBAN and be plausible length.
            if cleaned.count >= 15, cleaned.count <= 34,
               cleaned.prefix(2).allSatisfy({ $0.isLetter }),
               cleaned.dropFirst(2).prefix(2).allSatisfy({ $0.isNumber }) {
                out.append(RedactionMatch(range: r, kind: .iban))
            }
        }

        // SORT CODE (labelled): redact number span only
        out += groupRanges(
            input,
            pattern: #"\b(sort\s*code|s\/c)\s*(?:is|:)?\s*(\d{2}[-\s]?\d{2}[-\s]?\d{2})\b"#,
            options: [.caseInsensitive],
            group: 2
        ).map { RedactionMatch(range: $0, kind: .sortcode) }

        // SORT CODE (standalone) only when formatted with separators
        out += ranges(
            input,
            pattern: #"\b\d{2}[-\s]\d{2}[-\s]\d{2}\b"#,
            options: [.caseInsensitive]
        ).map { RedactionMatch(range: $0, kind: .sortcode) }

        // ACCOUNT NUMBER (labelled):
        // - allow "account is ..." as well as "account number is ..."
        // - capture a bounded number-ish span and then digit-count validate
        let acctGroupRanges = groupRanges(
            input,
            pattern: #"\b((?:bank\s*)?account(?:\s*(?:number|no\.?|#))?|acc(?:ount)?(?:\s*(?:number|no\.?|#))?|acct(?:\.|ount)?(?:\s*(?:number|no\.?|#))?|a\/c)\s*(?:is|:)?\s*([0-9](?:[0-9\s-]{3,}[0-9])?)\b"#,
            options: [.caseInsensitive],
            group: 2
        )
        for r in acctGroupRanges {
            let snippet = substring(input, nsRange: r)
            let digits = snippet.filter { $0.isNumber }
            // Practical: 6–12 digits (UK account usually 8; keep room for variants).
            if (6...12).contains(digits.count) {
                out.append(RedactionMatch(range: r, kind: .account))
            }
        }

        // NINO
        out += ranges(
            input,
            pattern: #"\b[A-CEGHJ-PR-TW-Z]{2}\d{6}[A-D]\b"#,
            options: [.caseInsensitive]
        ).map { RedactionMatch(range: $0, kind: .nino) }

        // UTR (contextual): redact digits span only
        out += groupRanges(
            input,
            pattern: #"\b(utr|unique\s*taxpayer\s*reference)\s*(?:is|:)?\s*(\d{10})\b"#,
            options: [.caseInsensitive],
            group: 2
        ).map { RedactionMatch(range: $0, kind: .utr) }

        // VAT (contextual): redact numeric span only
        out += groupRanges(
            input,
            pattern: #"\b(vat\s*(?:number|no\.?|#))\s*(?:is|:)?\s*(?:GB)?\s*(\d{9}(?:\d{3})?)\b"#,
            options: [.caseInsensitive],
            group: 2
        ).map { RedactionMatch(range: $0, kind: .vat) }

        // BIC/SWIFT – CONTEXTUAL ONLY to avoid false positives on random words.
        // We only redact codes when near "BIC" or "SWIFT".
        out += bicMatchesContextual(in: input)

        // CARD detection (careful)
        out += cardMatches(in: input)

        return out
    }

    private func bicMatchesContextual(in input: String) -> [RedactionMatch] {
        // Look for "BIC" / "SWIFT" labels and capture the code next to them.
        // Accept spaced codes by allowing optional separators and validating after cleanup.
        let codeRanges = groupRanges(
            input,
            pattern: #"\b(?:bic|swift)(?:\s*code)?\s*(?:is|:)?\s*([A-Z0-9](?:[A-Z0-9\s-]{6,}[A-Z0-9])?)\b"#,
            options: [.caseInsensitive],
            group: 1
        )

        var out: [RedactionMatch] = []
        for r in codeRanges {
            let snippet = substring(input, nsRange: r)
            let cleaned = snippet.filter { $0.isLetter || $0.isNumber }.uppercased()
            // BIC is 8 or 11 characters: AAAABBCC(DDD)
            if cleaned.count == 8 || cleaned.count == 11 {
                // Validate basic BIC structure to reduce false positives.
                let chars = Array(cleaned)
                let first4 = chars.prefix(4)
                let next2 = chars.dropFirst(4).prefix(2)
                if first4.allSatisfy({ $0.isLetter }),
                   next2.allSatisfy({ $0.isLetter }) {
                    out.append(RedactionMatch(range: r, kind: .bic))
                }
            }
        }
        return out
    }

    private func cardMatches(in input: String) -> [RedactionMatch] {
        let candidateRanges = ranges(
            input,
            pattern: #"\b(?:\d[ -]*?){13,19}\b"#,
            options: []
        )

        var out: [RedactionMatch] = []
        for r in candidateRanges {
            let snippet = substring(input, nsRange: r)
            let digits = snippet.compactMap { $0.wholeNumberValue }
            guard (13...19).contains(digits.count) else { continue }

            if luhnValid(digits) {
                out.append(RedactionMatch(range: r, kind: .card))
                continue
            }

            if hasCardContext(around: r, in: input, window: 28) {
                out.append(RedactionMatch(range: r, kind: .cardQ))
            }
        }
        return out
    }

    private func hasCardContext(around range: NSRange, in input: String, window: Int) -> Bool {
        let ns = input as NSString
        let start = max(0, range.location - window)
        let end = min(ns.length, range.location + range.length + window)
        let ctxRange = NSRange(location: start, length: max(0, end - start))
        let context = ns.substring(with: ctxRange).lowercased()

        let keywords = [
            "card", "debit", "credit", "visa", "mastercard", "amex", "american express",
            "cvv", "cvc", "expiry", "expiration", "exp date"
        ]
        return keywords.contains(where: { context.contains($0) })
    }

    // MARK: - Custom dictionary matches

    private func customMatches(in input: String, excluding structural: [RedactionMatch]) -> [RedactionMatch] {
        let occupied = structural

        let cleanedTokens = tokens
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .sorted { $0.count > $1.count }

        guard !cleanedTokens.isEmpty else { return [] }

        var out: [RedactionMatch] = []

        for token in cleanedTokens {
            let escaped = NSRegularExpression.escapedPattern(for: token)
            let pattern = "(?<![\\p{L}\\p{N}_])\(escaped)(?![\\p{L}\\p{N}_])"

            for r in ranges(input, pattern: pattern, options: [.caseInsensitive]) {
                if occupied.contains(where: { NSIntersectionRange($0.range, r).length > 0 }) {
                    continue
                }
                out.append(RedactionMatch(range: r, kind: .custom))
            }
        }

        return out
    }

    // MARK: - Overlap resolution

    private func chooseNonOverlapping(_ candidates: [RedactionMatch]) -> [RedactionMatch] {
        guard !candidates.isEmpty else { return [] }

        let sorted = candidates.sorted { a, b in
            if a.kind.rawValue != b.kind.rawValue { return a.kind.rawValue > b.kind.rawValue }
            if a.range.length != b.range.length { return a.range.length > b.range.length }
            return a.range.location < b.range.location
        }

        var chosen: [RedactionMatch] = []
        for m in sorted {
            if chosen.contains(where: { $0.overlaps(m) }) { continue }
            chosen.append(m)
        }

        return chosen.sorted { $0.range.location < $1.range.location }
    }

    // MARK: - Apply replacements

    private func apply(matches: [RedactionMatch], to input: String) -> (String, Bool) {
        guard !matches.isEmpty else { return (input, false) }

        let ns = input as NSString
        var cursor = 0
        var parts: [String] = []
        parts.reserveCapacity(matches.count * 2 + 1)

        for m in matches {
            if m.range.location < cursor { continue }

            if cursor < m.range.location {
                parts.append(ns.substring(with: NSRange(location: cursor, length: m.range.location - cursor)))
            }

            parts.append(m.replacement)
            cursor = m.range.location + m.range.length
        }

        if cursor < ns.length {
            parts.append(ns.substring(from: cursor))
        }

        return (parts.joined(), true)
    }

    // MARK: - Regex helpers

    private func ranges(
        _ input: String,
        pattern: String,
        options: NSRegularExpression.Options = []
    ) -> [NSRange] {
        guard let re = try? NSRegularExpression(pattern: pattern, options: options) else { return [] }
        let full = NSRange(input.startIndex..<input.endIndex, in: input)
        return re.matches(in: input, options: [], range: full).map { $0.range }
    }

    private func groupRanges(
        _ input: String,
        pattern: String,
        options: NSRegularExpression.Options = [],
        group: Int
    ) -> [NSRange] {
        guard let re = try? NSRegularExpression(pattern: pattern, options: options) else { return [] }
        let full = NSRange(input.startIndex..<input.endIndex, in: input)

        var out: [NSRange] = []
        for m in re.matches(in: input, options: [], range: full) {
            guard group <= m.numberOfRanges - 1 else { continue }
            let r = m.range(at: group)
            guard r.location != NSNotFound, r.length > 0 else { continue }
            out.append(r)
        }
        return out
    }

    private func substring(_ input: String, nsRange: NSRange) -> String {
        guard let r = Range(nsRange, in: input) else { return "" }
        return String(input[r])
    }

    // MARK: - Luhn

    private func luhnValid(_ digits: [Int]) -> Bool {
        guard !digits.isEmpty else { return false }
        var sum = 0
        var shouldDouble = false

        for d in digits.reversed() {
            var n = d
            if shouldDouble {
                n *= 2
                if n > 9 { n -= 9 }
            }
            sum += n
            shouldDouble.toggle()
        }

        return sum % 10 == 0
    }
}

