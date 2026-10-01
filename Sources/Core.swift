import Foundation
import CoreFoundation

enum QuotaError: LocalizedError {
    case message(String)
    var errorDescription: String? { if case .message(let s) = self { return s }; return nil }
}
enum Connection: String, Codable, CaseIterable {
    case unconnected, manual, codexbar, api
    var label: String {
        switch self {
        case .unconnected: return "연결 전"
        case .manual: return "직접 입력"
        case .codexbar: return "CodexBar 연결"
        case .api: return "조회 API 연결"
        }
    }
}
struct Subscription: Codable, Identifiable, Equatable {
    var id = UUID()
    var name = "새 구독"
    var plan = ""
    var enabled = true
    var pinned = false
    var connection: Connection = .unconnected
    var dashboard = ""
    var provider = "claude"
    var window = "primary"
    var endpoint = ""
    var valuePath = "remaining"
    var totalPath = "total"
    var resetPath = "resetsAt"
    var valueIsUsed = false
    var unit = "크레딧"
    var manualRemaining = ""
    var manualTotal = ""
    var manualReset = ""
    var manualUpdatedAt: Date?
    static var defaults: [Subscription] { [
        Subscription(name: "Claude", plan: "구독", dashboard: "https://claude.ai/settings/usage"),
        Subscription(name: "ChatGPT", plan: "Work / Codex", dashboard: "https://chatgpt.com", provider: "codex")
    ] }
}
struct Snapshot {
    var remaining: Double
    var total: Double?
    var unit: String
    var reset: Date?
    var updatedAt: Date
    var additionalWindows: [Snapshot] = []
    var fraction: Double? { guard let total, total > 0 else { return nil }; return min(1, max(0, remaining / total)) }
    var usedFraction: Double? { fraction.map { 1 - $0 } }
    var display: String { remaining.formatted(.number.precision(.fractionLength(0...1))) + (unit == "%" ? "%" : " " + unit) }
}
struct Configuration: Codable {
    var subscriptions = Subscription.defaults
    var refreshSeconds = 300
}
enum Parser {
    static func date(_ value: Any?) -> Date? {
        guard let s = value as? String, !s.isEmpty else { return nil }
        let f = ISO8601DateFormatter()
        if let d = f.date(from: s) { return d }
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f.date(from: s)
    }
    static func value(_ object: Any, path: String) -> Any? {
        guard !path.isEmpty else { return nil }
        return path.split(separator: ".").reduce(Optional(object)) { current, part in
            if let dict = current as? [String: Any] { return dict[String(part)] }
            if let array = current as? [Any], let i = Int(part), array.indices.contains(i) { return array[i] }
            return nil
        }
    }
    static func number(_ object: Any?) -> Double? {
        guard let n = object as? NSNumber, CFGetTypeID(n) != CFBooleanGetTypeID(), n.doubleValue.isFinite else { return nil }
        return n.doubleValue
    }
    static func checked(_ remaining: Double, total: Double?, unit: String, reset: Date?, updatedAt: Date) throws -> Snapshot {
        guard remaining.isFinite, remaining >= 0 else { throw QuotaError.message("잔여량은 0 이상의 숫자여야 합니다.") }
        if let total { guard total.isFinite, total > 0, remaining <= total else { throw QuotaError.message("총량은 0보다 크고 잔여량 이상이어야 합니다.") } }
        return Snapshot(remaining: remaining, total: total, unit: unit, reset: reset, updatedAt: updatedAt)
    }
    static func manual(_ s: Subscription) throws -> Snapshot {
        guard let n = Double(s.manualRemaining), let updated = s.manualUpdatedAt else { throw QuotaError.message("설정에서 잔여량을 입력해 주세요.") }
        let total = s.manualTotal.isEmpty ? nil : Double(s.manualTotal)
        if !s.manualTotal.isEmpty && total == nil { throw QuotaError.message("총량을 숫자로 입력해 주세요.") }
        return try checked(n, total: total, unit: s.unit, reset: date(s.manualReset), updatedAt: updated)
    }
    static func api(_ data: Data, service s: Subscription) throws -> Snapshot {
        let json = try JSONSerialization.jsonObject(with: data)
        guard let n = number(value(json, path: s.valuePath)) else { throw QuotaError.message("응답에서 사용량 숫자를 찾지 못했습니다. JSON 경로를 확인하세요.") }
        let total = number(value(json, path: s.totalPath))
        if !s.totalPath.isEmpty && total == nil { throw QuotaError.message("총량 경로가 없거나 숫자가 아닙니다. 총량이 없으면 경로를 비워 주세요.") }
        if s.valueIsUsed && total == nil { throw QuotaError.message("사용량을 잔여량으로 변환하려면 총량이 필요합니다.") }
        return try checked(s.valueIsUsed ? total! - n : n, total: total, unit: s.unit, reset: date(value(json, path: s.resetPath)), updatedAt: Date())
    }
    static func codexbar(_ data: Data, service s: Subscription) throws -> Snapshot {
        if s.window == "both" {
            var primary = s; primary.window = "primary"
            var result = try codexbar(data, service: primary)
            var weekly = s; weekly.window = "secondary"
            if let week = try? codexbar(data, service: weekly) { result.additionalWindows = [week] }
            return result
        }
        let json = try JSONSerialization.jsonObject(with: data)
        let rows = (json as? [[String: Any]]) ?? ((json as? [String: Any]).map { [$0] } ?? [])
        let matching = rows.filter { ($0["provider"] as? String) == s.provider }
        guard matching.count == 1, let row = matching.first else { throw QuotaError.message("계정 결과가 없거나 여러 개입니다. CodexBar에서 사용할 계정을 확인해 주세요.") }
        guard row["error"] == nil || row["error"] is NSNull,
              let used = number(value(row, path: "usage.\(s.window).usedPercent")), used >= 0, used <= 100,
              let updated = date(value(row, path: "usage.updatedAt")) else { throw QuotaError.message("사용량을 읽지 못했습니다. CodexBar 로그인과 조회 결과를 확인하세요.") }
        return try checked(100 - used, total: 100, unit: "%", reset: date(value(row, path: "usage.\(s.window).resetsAt")), updatedAt: updated)
    }
}
