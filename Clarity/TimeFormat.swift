import Foundation

func mmss(_ t: TimeInterval) -> String {
    guard t.isFinite, t >= 0 else { return "0:00" }
    let total = Int(t.rounded(.down))
    let m = total / 60
    let s = total % 60
    return "\(m):" + String(format: "%02d", s)
}

