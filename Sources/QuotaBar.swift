import SwiftUI
import AppKit
import Security
import ServiceManagement

struct SecretStore {
    static func query(_ id: UUID) -> [String: Any] { [kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: "local.quotabar.token", kSecAttrAccount as String: id.uuidString] }
    static func read(_ id: UUID) throws -> String {
        var q = query(id); q[kSecReturnData as String] = true; q[kSecMatchLimit as String] = kSecMatchLimitOne
        var out: CFTypeRef?
        let status = SecItemCopyMatching(q as CFDictionary, &out)
        if status == errSecItemNotFound { return "" }
        guard status == errSecSuccess, let data = out as? Data, let str = String(data: data, encoding: .utf8) else { throw QuotaError.message("키체인에서 인증 정보를 읽지 못했습니다.") }
        return str
    }
    static func save(_ token: String, id: UUID) throws {
        let q = query(id)
        if token.isEmpty {
            let status = SecItemDelete(q as CFDictionary)
            guard status == errSecSuccess || status == errSecItemNotFound else { throw QuotaError.message("키체인 삭제에 실패했습니다.") }; return
        }
        let attributes = [kSecValueData as String: Data(token.utf8)]
        var status = SecItemUpdate(q as CFDictionary, attributes as CFDictionary)
        if status == errSecItemNotFound {
            var entry = q; entry[kSecValueData as String] = Data(token.utf8)
            entry[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
            status = SecItemAdd(entry as CFDictionary, nil)
        }
        guard status == errSecSuccess else { throw QuotaError.message("키체인 저장에 실패했습니다.") }
    }
}
final class NoRedirect: NSObject, URLSessionTaskDelegate {
    func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) { completionHandler(nil) }
}
enum Fetcher {
    static func fetch(_ s: Subscription) async throws -> Snapshot {
        switch s.connection {
        case .unconnected: throw QuotaError.message("설정에서 연결 방식을 선택해 주세요.")
        case .manual: return try Parser.manual(s)
        case .api:
            guard let url = URL(string: s.endpoint), url.scheme == "https", url.host != nil, url.user == nil, url.password == nil else { throw QuotaError.message("유효한 HTTPS 조회 주소를 입력해 주세요.") }
            var request = URLRequest(url: url); request.timeoutInterval = 20; request.httpMethod = "GET"
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            let token = try SecretStore.read(s.id)
            if !token.isEmpty { request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }
            let config = URLSessionConfiguration.ephemeral
            config.httpCookieStorage = nil; config.urlCache = nil
            let session = URLSession(configuration: config, delegate: NoRedirect(), delegateQueue: nil)
            defer { session.invalidateAndCancel() }
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else { throw QuotaError.message("서버 응답을 확인할 수 없습니다.") }
            guard (200...299).contains(http.statusCode) else { throw QuotaError.message("조회 실패 · HTTP \(http.statusCode). 주소와 인증을 확인하세요.") }
            guard data.count <= 2_000_000 else { throw QuotaError.message("응답이 너무 큽니다.") }
            return try Parser.api(data, service: s)
        case .codexbar:
            return try await Task.detached(priority: .utility) {
                guard ["claude", "codex"].contains(s.provider) else { throw QuotaError.message("지원하지 않는 조회 서비스입니다.") }
                guard let path = ToolLocator.helper else { throw QuotaError.message("CodexBar 조회 도구가 없습니다. 설정 → 연결 도우미에서 설치 안내를 확인해 주세요.") }
                guard ToolLocator.executable(s.provider) != nil else { throw QuotaError.message("\(s.provider == "claude" ? "Claude Code" : "Codex CLI")가 없습니다. 설정 → 연결 도우미에서 설치해 주세요.") }
                let process = Process(); process.executableURL = URL(fileURLWithPath: path)
                // Fixed arguments only; never execute user-entered shell commands.
                let isClaude = s.provider == "claude"
                process.arguments = ["usage", "--provider", s.provider, "--format", "json", "--source", "cli"]
                do {
                    // Finder-launched apps do not inherit the terminal's PATH.
                    var environment = ProcessInfo.processInfo.environment
                    environment["PATH"] = ToolLocator.searchPath
                    process.environment = environment
                    let workspace = URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("QuotaBar-Connect", isDirectory: true)
                    try FileManager.default.createDirectory(at: workspace, withIntermediateDirectories: true)
                    process.currentDirectoryURL = workspace
                }
                let pipe = Pipe(); process.standardOutput = pipe; process.standardError = FileHandle.nullDevice
                try process.run()
                let timeout = DispatchWorkItem { if process.isRunning { process.terminate() } }
                DispatchQueue.global().asyncAfter(deadline: .now() + 60, execute: timeout)
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                process.waitUntilExit(); timeout.cancel()
                guard process.terminationStatus == 0 else { throw QuotaError.message(isClaude ? "Claude 조회 실패. Claude Code 로그인과 QuotaBar-Connect 폴더 신뢰 설정을 확인해 주세요." : "Codex 조회 실패. 터미널에서 codex login으로 ChatGPT 계정을 연결해 주세요.") }
                var combined = s
                combined.window = "both"
                return try Parser.codexbar(data, service: combined)
            }.value
        }
    }
}
@MainActor final class Store: ObservableObject {
    @Published var config: Configuration
    @Published var readings: [UUID: Snapshot] = [:]
    @Published var errors: [UUID: String] = [:]
    @Published var refreshing = false
    @Published var storageError: String?
    @Published var lastRefreshFinished: Date?
    private var wakeObserver: NSObjectProtocol?
    private var timer: Timer?
    private var task: Task<Void, Never>?
    private var revision = UUID()
    private let file: URL
    init() {
        let folder = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("QuotaBar")
        file = folder.appendingPathComponent("subscriptions.json")
        config = Configuration()
        do {
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            if FileManager.default.fileExists(atPath: file.path) { config = try JSONDecoder().decode(Configuration.self, from: Data(contentsOf: file)) }
        } catch { storageError = "설정 파일을 읽지 못했습니다. 기존 파일을 덮어쓰지 않도록 앱을 재시작하기 전에 확인해 주세요." }
        schedule()
        wakeObserver = NSWorkspace.shared.notificationCenter.addObserver(forName: NSWorkspace.didWakeNotification, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in self?.refresh() }
        }
        Task { @MainActor [weak self] in self?.refresh() }
    }
    var visible: [Subscription] { config.subscriptions.filter(\.enabled) }
    func stale(_ snapshot: Snapshot) -> Bool { Date().timeIntervalSince(snapshot.updatedAt) > Double(config.refreshSeconds * 2 + 30) }
    var title: String {
        if let s = visible.first(where: \.pinned) {
            if let r = readings[s.id], errors[s.id] == nil, (s.connection == .manual || !stale(r)) { return "\(s.name) \(r.display)" }
            return "\(s.name) —"
        }
        return "구독"
    }
    func persist() throws {
        if storageError != nil { throw QuotaError.message("설정 파일 오류를 먼저 확인해 주세요. 파일 위치: ~/Library/Application Support/QuotaBar/subscriptions.json") }
        let data = try JSONEncoder().encode(config)
        try data.write(to: file, options: .atomic)
        try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: file.path)
    }
    func save(_ service: Subscription) throws {
        let old = config
        if service.pinned { for i in config.subscriptions.indices { config.subscriptions[i].pinned = false } }
        if let i = config.subscriptions.firstIndex(where: { $0.id == service.id }) { config.subscriptions[i] = service }
        else { config.subscriptions.append(service) }
        do { try persist() } catch { config = old; throw error }
        readings.removeValue(forKey: service.id); errors.removeValue(forKey: service.id)
        invalidateAndRefresh()
    }
    func delete(_ id: UUID) throws {
        let old = config
        config.subscriptions.removeAll { $0.id == id }
        do { try persist() } catch { config = old; throw error }
        try? SecretStore.save("", id: id)
        readings.removeValue(forKey: id); errors.removeValue(forKey: id)
        invalidateAndRefresh()
    }
    func interval(_ value: Int) throws {
        let old = config.refreshSeconds; config.refreshSeconds = value
        do { try persist() } catch { config.refreshSeconds = old; throw error }
        schedule()
    }
    func schedule() {
        timer?.invalidate()
        let next = Timer(timeInterval: Double(max(60, config.refreshSeconds)), repeats: true) { [weak self] _ in Task { @MainActor in self?.refresh() } }
        RunLoop.main.add(next, forMode: .common)
        timer = next
    }
    private func invalidateAndRefresh() {
        revision = UUID(); task?.cancel(); refreshing = false; refresh()
    }
    func refresh() {
        guard !refreshing else { return }
        refreshing = true
        let services = visible, version = revision
        task = Task {
            for s in services {
                if Task.isCancelled || version != revision { return }
                do {
                    let result = try await Fetcher.fetch(s)
                    guard !Task.isCancelled, version == revision else { return }
                    readings[s.id] = result; errors.removeValue(forKey: s.id)
                } catch {
                    guard !Task.isCancelled, version == revision else { return }
                    errors[s.id] = (error as? QuotaError)?.errorDescription ?? "연결에 실패했습니다. 네트워크와 설정을 확인해 주세요."
                }
            }
            if version == revision { refreshing = false; lastRefreshFinished = Date() }
        }
    }
}
let accent = Color.accentColor
func openDashboard(_ value: String) {
    if let url = URL(string: value), url.scheme == "https" { NSWorkspace.shared.open(url) }
}
// Native popover material inherits macOS appearance and wallpaper tint.
final class PopoverMaterialView: NSVisualEffectView {
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        window?.isOpaque = false
        window?.backgroundColor = .clear
    }
}
struct PopoverMaterial: NSViewRepresentable {
    func makeNSView(context: Context) -> PopoverMaterialView {
        let view = PopoverMaterialView()
        view.material = .popover
        view.blendingMode = .behindWindow
        view.state = .active
        return view
    }
    func updateNSView(_ view: PopoverMaterialView, context: Context) {
        view.material = .popover
        // No appearance override: light/dark changes propagate from macOS.
    }
}
struct SystemPopoverBackground: View {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    var body: some View {
        Group {
            if reduceTransparency { Color(nsColor: .windowBackgroundColor) }
            else { PopoverMaterial() }
        }.allowsHitTesting(false)
    }
}
struct UsageBar: View {
    let used: Double?
    let stale: Bool
    @Environment(\.colorSchemeContrast) private var systemContrast
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule().fill(Color(nsColor: .separatorColor).opacity(systemContrast == ColorSchemeContrast.increased ? 1 : 0.55))
                if let used {
                    Capsule().fill(stale ? Color.secondary : Color.accentColor)
                        .frame(width: geometry.size.width * CGFloat(min(1, max(0, used))))
                }
            }
        }
        .frame(height: 4)
        .accessibilityLabel("사용량")
        .accessibilityValue(used.map { "\(Int(($0 * 100).rounded()))퍼센트 사용" } ?? "사용 비율을 확인할 수 없음")
    }
}
struct QuotaCard: View {
    @EnvironmentObject var store: Store
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.colorSchemeContrast) private var systemContrast
    let service: Subscription
    private var bothWindows: Bool { service.connection == .codexbar }
    private var primaryTitle: String { "현재 사용량" }
    var body: some View {
        let reading = store.readings[service.id]
        let error = store.errors[service.id]
        TimelineView(.periodic(from: .now, by: 60)) { context in
            let stale = error != nil || (reading.map { context.date.timeIntervalSince($0.updatedAt) > Double(store.config.refreshSeconds * 2 + 30) } ?? false) && service.connection != .manual
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Button { openDashboard(service.dashboard) } label: {
                        Text(service.provider == "codex" || service.name.lowercased().contains("chatgpt") ? "G" : String(service.name.prefix(1)))
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Color.black.opacity(0.8))
                            .frame(width: 24, height: 24)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 7))
                    }.buttonStyle(.plain).help(service.name + " · 서비스 열기")
                        .accessibilityLabel(service.name)
                    Text(service.name).font(.system(size: 12, weight: .semibold)).lineLimit(1)
                    Spacer()
                }
                .padding(.bottom, 10)
                quotaRow(primaryTitle, reading: reading, stale: stale, now: context.date)
                if bothWindows {
                    quotaRow("주간 사용량", reading: reading?.additionalWindows.first, stale: stale, now: context.date)
                        .padding(.top, 18)
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, 14)
            .frame(maxWidth: .infinity)
            .frame(height: bothWindows ? 158 : 102, alignment: .top)
        }
        .background(Color.white.opacity(colorScheme == .dark ? 0.055 : 0.26))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous)
            .strokeBorder(Color.primary.opacity(systemContrast == .increased ? 0.35 : 0), lineWidth: 1))
        .help(tooltip(reading, error: error))
    }
    private func quotaRow(_ title: String, reading: Snapshot?, stale: Bool, now: Date) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(title).font(.system(size: 12, weight: .semibold)).fixedSize()
                Spacer(minLength: 2)
                Text(status(reading, stale: stale, now: now))
                    .font(.system(size: 12)).foregroundStyle(.secondary)
                    .monospacedDigit().lineLimit(1)
            }
            UsageBar(used: reading?.usedFraction, stale: stale)
        }
        .accessibilityElement(children: .combine)
    }
    private func status(_ reading: Snapshot?, stale: Bool, now: Date) -> String {
        guard let reading else {
            if service.connection == .unconnected { return "설정에서 연결" }
            if store.errors[service.id] != nil { return "조회 실패" }
            return store.refreshing ? "조회 중…" : "사용량 확인 불가"
        }
        let value = reading.usedFraction.map { "\(Int(($0 * 100).rounded()))%" } ?? (reading.display + " 남음")
        if stale { return value + " • 갱신 필요" }
        if service.connection == .manual { return value + " • 직접 입력" }
        guard let reset = reading.reset else { return value + " • 리셋 정보 없음" }
        let minutes = Int(ceil(reset.timeIntervalSince(now) / 60))
        if minutes <= 0 { return value + " • 리셋 확인 필요" }
        let days = minutes / 1440, hours = minutes % 1440 / 60, remainder = minutes % 60
        let duration: String
        if days > 0 { duration = "\(days)일 \(hours)시간 \(remainder)분" }
        else if hours > 0 { duration = "\(hours)시간 \(remainder)분" }
        else { duration = "\(remainder)분" }
        return value + " • " + duration + " 뒤 리셋"
    }
    private func tooltip(_ reading: Snapshot?, error: String?) -> String {
        var lines = [service.name, service.plan, "막대와 퍼센트는 사용한 비율입니다."]
        if let reading {
            lines.append("남은 양: " + reading.display)
            lines.append("마지막 확인: " + reading.updatedAt.formatted(date: .abbreviated, time: .shortened))
            if let reset = reading.reset { lines.append("초기화: " + reset.formatted(date: .abbreviated, time: .shortened)) }
            if let weekly = reading.additionalWindows.first {
                lines.append("주간 남은 양: " + weekly.display)
                if let reset = weekly.reset { lines.append("주간 초기화: " + reset.formatted(date: .abbreviated, time: .shortened)) }
            }
        }
        if let error { lines.append(error) }
        return lines.filter { !$0.isEmpty }.joined(separator: "\n")
    }
}
struct MenuView: View {
    @EnvironmentObject var store: Store
    @Environment(\.openWindow) var openWindow
    // Explicit intrinsic height prevents the menu host from collapsing a ScrollView.
    private var screen: NSRect { (NSScreen.main ?? NSScreen.screens.first)?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1280, height: 720) }
    private var rowStride: Int { store.visible.contains { $0.connection == .codexbar } ? 158 : 102 }
    private var rowsPerColumn: Int { max(1, Int((screen.height - 100) / CGFloat(rowStride))) }
    private var columnCount: Int {
        let needed = max(1, (store.visible.count + rowsPerColumn - 1) / rowsPerColumn)
        return min(needed, max(1, Int((screen.width - 40) / 354)))
    }
    private var rowCount: Int { max(1, (store.visible.count + columnCount - 1) / columnCount) }
    private var overflow: Bool { rowCount > rowsPerColumn }
    private var gridHeight: CGFloat {
        if overflow { return CGFloat(rowsPerColumn * rowStride) }
        let services = store.visible
        var height: CGFloat = 0
        for start in stride(from: 0, to: services.count, by: columnCount) {
            let row = services[start..<min(start + columnCount, services.count)]
            height += row.contains { $0.connection == .codexbar } ? 158 : 102
        }
        return max(0, height)
    }
    private var grid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.fixed(354), spacing: 8), count: columnCount), spacing: 0) {
            ForEach(store.visible) { QuotaCard(service: $0) }
        }
    }
    var body: some View {
        VStack(spacing: 0) {
            if let error = store.storageError {
                Text(error).font(.caption).foregroundStyle(.orange).lineLimit(2).help(error).padding(.horizontal, 14).padding(.bottom, 6)
            }
            Group {
                if store.visible.isEmpty {
                    Text("아래 설정에서 구독을 추가해 주세요.").font(.caption).foregroundStyle(.secondary).frame(height: 62)
                } else if overflow {
                    // Only used when every available screen column is full.
                    ScrollView { grid }.frame(height: gridHeight)
                } else {
                    grid.frame(height: gridHeight)
                }
            }
            HStack {
                Button { openWindow(id: "settings"); NSApp.activate(ignoringOtherApps: true) } label: {
                    Label("구독 관리 · 설정", systemImage: "gearshape").font(.system(size: 11))
                }.buttonStyle(.plain)
                Spacer()
                Button { store.refresh() } label: {
                    Image(systemName: "arrow.clockwise").font(.system(size: 11))
                }.buttonStyle(.plain).disabled(store.refreshing).help("지금 새로고침")
                Text(store.refreshing ? "갱신 중…" : "\(store.config.refreshSeconds / 60)분마다").font(.system(size: 10)).foregroundStyle(.secondary)
            }.padding(.horizontal, 14).frame(height: 34)
        }
        .frame(width: CGFloat(columnCount * 354 + (columnCount - 1) * 8))
        .fixedSize(horizontal: false, vertical: true)
        .background(SystemPopoverBackground())
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
struct SettingsView: View {
    @EnvironmentObject var store: Store
    @State private var editing: Subscription?
    @State private var deleting: Subscription?
    @State private var error: String?
    @State private var showSetup = false
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                VStack(alignment: .leading, spacing: 5) { Text("구독 관리").font(.title2.bold()); Text("서비스를 추가하고 연결 방식을 바꿔보세요.").foregroundStyle(.secondary) }
                Spacer()
                Button { editing = Subscription() } label: { Label("구독 추가", systemImage: "plus") }.buttonStyle(.borderedProminent).tint(accent)
            }
            Button("연결 도우미 · 설치 확인 / 로그인") { showSetup = true }
            ScrollView {
                VStack(spacing: 8) {
                    ForEach(store.config.subscriptions) { s in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) { Text(s.name).font(.headline); Text(s.connection.label + (s.enabled ? "" : " · 숨김") + (s.pinned ? " · 상단 고정" : "")).font(.caption).foregroundStyle(.secondary) }
                            if let message = store.errors[s.id], s.connection != .unconnected {
                                Text(message).font(.caption).foregroundStyle(.orange).lineLimit(2).frame(maxWidth: 220).help(message)
                            }
                            Spacer()
                            Button("수정") { editing = s }
                            Button { deleting = s } label: { Image(systemName: "trash") }.help("구독 삭제")
                        }.padding(12).background(Color(nsColor: .controlBackgroundColor)).clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
            }
            Divider()
            Picker("자동 갱신", selection: Binding(get: { store.config.refreshSeconds }, set: { n in do { try store.interval(n) } catch { self.error = error.localizedDescription } })) {
                Text("1분").tag(60); Text("5분").tag(300); Text("15분").tag(900)
            }.frame(width: 220)
            Toggle("맥에 로그인하면 자동 실행", isOn: Binding(get: { launchAtLogin }, set: { value in
                do { if value { try SMAppService.mainApp.register() } else { try SMAppService.mainApp.unregister() }; launchAtLogin = SMAppService.mainApp.status == .enabled
                    if value && !launchAtLogin { error = "시스템 설정 → 일반 → 로그인 항목에서 QuotaBar를 허용해 주세요." }
                } catch { self.error = error.localizedDescription }
            }))
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(store.refreshing ? "사용량 조회 중…" : "자동 조회 대기 중")
                    if let finished = store.lastRefreshFinished {
                        Text("최근 조회 완료: " + finished.formatted(date: .omitted, time: .standard))
                    }
                    Text("연결된 항목 중 조회 실패: \(store.visible.filter { $0.connection != .unconnected && store.errors[$0.id] != nil }.count)개")
                }.font(.caption).foregroundStyle(.secondary)
                Spacer()
                Button("QuotaBar 종료") { NSApplication.shared.terminate(nil) }
            }
            Text("직접 입력한 값은 자동으로 갱신되지 않습니다. API 연결은 해당 서비스의 사용량 조회 기능이 필요합니다.").font(.caption).foregroundStyle(.secondary)
            if let error { Text(error).font(.caption).foregroundStyle(.orange) }
        }.padding(24).frame(width: 590, height: 600)
        .sheet(isPresented: $showSetup) { SetupView().environmentObject(store) }
        .sheet(item: $editing) { s in Editor(service: s).environmentObject(store) }
        .confirmationDialog("이 구독을 삭제할까요?", isPresented: Binding(get: { deleting != nil }, set: { if !$0 { deleting = nil } })) {
            Button("삭제", role: .destructive) { if let s = deleting { do { try store.delete(s.id) } catch { self.error = error.localizedDescription } }; deleting = nil }
            Button("취소", role: .cancel) { deleting = nil }
        }
    }
}
struct Editor: View {
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) var dismiss
    @State var service: Subscription
    @State private var token = ""
    @State private var changeToken = false
    @State private var error: String?
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("구독 설정").font(.title2.bold())
            Form {
                TextField("서비스 이름", text: $service.name)
                TextField("요금제 / 설명", text: $service.plan)
                TextField("서비스 바로가기 (HTTPS)", text: $service.dashboard)
                Toggle("위젯에 표시", isOn: $service.enabled)
                Toggle("메뉴 막대에 이 서비스의 잔여량 표시", isOn: $service.pinned)
                Picker("연결 방식", selection: $service.connection) { ForEach(Connection.allCases, id: \.self) { Text($0.label).tag($0) } }
                switch service.connection {
                case .unconnected:
                    Text("아직 연결되지 않았습니다. 사용량을 조회할 수 없는 서비스는 직접 입력으로 관리할 수 있습니다.").font(.caption).foregroundStyle(.secondary)
                case .manual:
                    TextField("남은 양", text: $service.manualRemaining)
                    TextField("총량 (선택)", text: $service.manualTotal)
                    TextField("단위", text: $service.unit)
                    TextField("초기화 시각 (선택, ISO 8601)", text: $service.manualReset)
                    Text("예: 2026-10-01T00:00:00+09:00 · 저장 시각을 입력 시각으로 표시합니다.").font(.caption).foregroundStyle(.secondary)
                case .codexbar:
                    Picker("조회 서비스", selection: $service.provider) { Text("Claude").tag("claude"); Text("ChatGPT · Work / Codex").tag("codex") }
                    Text("표시 구간: 현재 세션(5시간) + 주간 사용 한도").font(.caption)
                    Text("로그인된 Claude Code 또는 Codex CLI로 조회합니다. CodexBar 앱은 설치만 되어 있으면 됩니다. ChatGPT 일반 채팅은 포함되지 않습니다. 두 구간의 사용률과 초기화까지 남은 시간을 한 카드에서 함께 표시합니다.").font(.caption).foregroundStyle(.secondary)
                    Link("CodexBar 설치 안내 ↗", destination: URL(string: "https://github.com/steipete/CodexBar")!)
                case .api:
                    TextField("조회 주소 (HTTPS GET)", text: $service.endpoint)
                    Toggle("인증 토큰 새로 저장 / 교체", isOn: $changeToken)
                    if changeToken { SecureField("Bearer 토큰 (빈칸 저장 시 삭제)", text: $token) }
                    TextField("잔여량 또는 사용량 JSON 경로", text: $service.valuePath)
                    Toggle("위 값은 사용한 양 (총량에서 차감)", isOn: $service.valueIsUsed)
                    TextField("총량 JSON 경로 (선택)", text: $service.totalPath)
                    TextField("초기화 시각 JSON 경로 (선택)", text: $service.resetPath)
                    TextField("표시 단위", text: $service.unit)
                    Text("예: data.remaining / data.total. 토큰은 이 맥의 키체인에 저장됩니다. API 키만으로 일반 채팅 구독 잔여량이 조회되는 것은 아닙니다.").font(.caption).foregroundStyle(.secondary)
                }
            }.formStyle(.grouped)
            if let error { Text(error).font(.caption).foregroundStyle(.red) }
            HStack {
                Spacer(); Button("취소") { dismiss() }.keyboardShortcut(.cancelAction)
                Button("저장 및 조회") { save() }.buttonStyle(.borderedProminent).tint(accent).keyboardShortcut(.defaultAction)
            }
        }.padding(22).frame(width: 570, height: 650)
    }
    func save() {
        do {
            service.name = service.name.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !service.name.isEmpty else { throw QuotaError.message("서비스 이름을 입력해 주세요.") }
            if !service.dashboard.isEmpty { guard let url = URL(string: service.dashboard), url.scheme == "https", url.host != nil else { throw QuotaError.message("바로가기는 HTTPS 주소로 입력해 주세요.") } }
            if service.connection == .manual {
                service.manualUpdatedAt = Date(); _ = try Parser.manual(service)
                if !service.manualReset.isEmpty && Parser.date(service.manualReset) == nil { throw QuotaError.message("초기화 시각 형식을 확인해 주세요.") }
            }
            if service.connection == .api {
                guard let url = URL(string: service.endpoint), url.scheme == "https", url.host != nil, url.user == nil, url.password == nil, !service.valuePath.isEmpty else { throw QuotaError.message("HTTPS 조회 주소와 JSON 경로를 입력해 주세요.") }
            }
            if service.connection == .codexbar { service.window = "both" }
            let previous = store.config.subscriptions.first { $0.id == service.id }
            let endpointChanged = previous.map { $0.endpoint != service.endpoint } ?? false
            if endpointChanged && !changeToken {
                // Never forward a previous endpoint's token to a newly entered host.
                try SecretStore.save("", id: service.id)
            }
            if changeToken { try SecretStore.save(token.trimmingCharacters(in: .whitespacesAndNewlines), id: service.id) }
            try store.save(service); dismiss()
        } catch { self.error = error.localizedDescription }
    }
}
@main struct QuotaBarApp: App {
    @StateObject private var store = Store()
    var body: some Scene {
        MenuBarExtra { MenuView().environmentObject(store).task { store.refresh() } } label: {
            Label(store.title, systemImage: "chart.bar.xaxis")
        }.menuBarExtraStyle(.window)
        Window("QuotaBar · 구독 관리", id: "settings") {
            SettingsView().environmentObject(store)
        }.windowResizability(.contentSize)
    }
}
