// TimeInterval+MMSS.swift
import Foundation

extension TimeInterval {
    var mmssString: String {
        let s = max(0, Int(self.rounded()))
        let m = s / 60
        let r = s % 60
        return String(format: "%d:%02d", m, r)
    }
}
