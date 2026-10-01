import Foundation
func expectFailure(_ label: String, _ run: () throws -> Void) {
    do { try run(); fatalError("Expected failure: \(label)") } catch { print("PASS \(label)") }
}
var api = Subscription()
api.connection = .api
let exactZero = try Parser.api(Data(#"{"remaining":0,"total":100}"#.utf8), service: api)
assert(exactZero.remaining == 0 && exactZero.fraction == 0)
expectFailure("missing is not zero") { _ = try Parser.api(Data(#"{"total":100}"#.utf8), service: api) }
expectFailure("boolean is not a number") { _ = try Parser.api(Data(#"{"remaining":true,"total":100}"#.utf8), service: api) }
expectFailure("over quota fails") { _ = try Parser.api(Data(#"{"remaining":110,"total":100}"#.utf8), service: api) }
api.valueIsUsed = true
let converted = try Parser.api(Data(#"{"remaining":30,"total":100}"#.utf8), service: api)
assert(converted.remaining == 70)
api.totalPath = ""
expectFailure("used needs total") { _ = try Parser.api(Data(#"{"remaining":30}"#.utf8), service: api) }
api.valueIsUsed = false; api.valuePath = "data.0.balance"
let nested = try Parser.api(Data(#"{"data":[{"balance":24}]}"#.utf8), service: api)
assert(nested.remaining == 24)
var claude = Subscription(); claude.provider = "claude"
let payload = Data(#"[{"provider":"claude","usage":{"primary":{"usedPercent":28,"resetsAt":"2026-10-01T00:00:00Z"},"updatedAt":"2026-09-20T10:00:00Z"}}]"#.utf8)
let result = try Parser.codexbar(payload, service: claude)
assert(result.remaining == 72 && result.reset != nil)
claude.window = "secondary"
expectFailure("missing weekly stays unavailable") { _ = try Parser.codexbar(payload, service: claude) }
var manual = Subscription(); manual.manualRemaining = "0"; manual.manualUpdatedAt = Date()
let manualZero = try Parser.manual(manual)
assert(manualZero.remaining == 0)
manual.manualRemaining = "nan"
expectFailure("nonfinite rejected") { _ = try Parser.manual(manual) }
let config = Configuration()
let restored = try JSONDecoder().decode(Configuration.self, from: JSONEncoder().encode(config))
assert(restored.subscriptions == config.subscriptions)
assert(Parser.date("2026-09-20T12:30:00.123Z") != nil)
print("All QuotaBar core checks passed.")

// Usage bars fill with used quota, not remaining quota.
assert(exactZero.usedFraction == 1)
let allRemaining = try Parser.checked(100, total: 100, unit: "%", reset: nil, updatedAt: Date())
assert(allRemaining.usedFraction == 0)
let quarterUsed = try Parser.checked(75, total: 100, unit: "%", reset: nil, updatedAt: Date())
assert(quarterUsed.usedFraction == 0.25)
let unknownTotal = try Parser.checked(75, total: nil, unit: "credits", reset: nil, updatedAt: Date())
assert(unknownTotal.usedFraction == nil)
print("Usage bar boundary checks passed.")

// CLI response shape: both session and weekly windows, nullable tertiary.
let cliPayload = Data(#"[{"source":"claude","provider":"claude","usage":{"primary":{"usedPercent":4,"windowMinutes":300,"resetsAt":"2026-09-20T17:09:00Z"},"secondary":{"usedPercent":17,"windowMinutes":10080,"resetsAt":"2026-09-22T13:59:00Z"},"tertiary":null,"identity":{"providerID":"claude"},"updatedAt":"2026-09-20T12:58:10Z"}}]"#.utf8)
claude.window = "primary"
let cliSession = try Parser.codexbar(cliPayload, service: claude)
assert(cliSession.remaining == 96)
claude.window = "secondary"
let cliWeekly = try Parser.codexbar(cliPayload, service: claude)
assert(cliWeekly.remaining == 83)
print("Claude CLI response checks passed.")

// Shared Codex quota: credit balance zero must not override plan usage.
var codex = Subscription(); codex.provider = "codex"; codex.window = "both"
let codexPayload = Data(#"[{"provider":"codex","credits":{"remaining":0},"usage":{"primary":{"usedPercent":29,"resetsAt":"2026-09-28T19:28:48Z"},"secondary":{"usedPercent":29,"resetsAt":"2026-10-04T08:53:07Z"},"updatedAt":"2026-09-28T14:52:14Z"}}]"#.utf8)
let sharedQuota = try Parser.codexbar(codexPayload, service: codex)
assert(sharedQuota.remaining == 71)
assert(sharedQuota.additionalWindows.first?.remaining == 71)
assert(sharedQuota.reset != sharedQuota.additionalWindows.first?.reset)
claude.window = "both"
let missingWeekly = try Parser.codexbar(payload, service: claude)
assert(missingWeekly.remaining == 72 && missingWeekly.additionalWindows.isEmpty)
print("Two-window quota checks passed.")

// Regression: the default ChatGPT row must query Codex, not Claude.
assert(Subscription.defaults.first { $0.name == "ChatGPT" }?.provider == "codex")
print("Default provider regression check passed.")
