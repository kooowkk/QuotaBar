import SwiftUI
import AppKit

enum ToolLocator {
    static var searchPath: String {
        NSHomeDirectory() + "/.local/bin:/opt/homebrew/bin:/usr/local/bin:" + (ProcessInfo.processInfo.environment["PATH"] ?? "/usr/bin:/bin:/usr/sbin:/sbin")
    }
    static func executable(_ name: String) -> String? {
        searchPath.split(separator: ":").map { String($0) + "/" + name }
            .first { FileManager.default.isExecutableFile(atPath: $0) }
    }
    static var helper: String? {
        let candidates = ["/Applications/CodexBar.app/Contents/Helpers/CodexBarCLI",
            NSHomeDirectory() + "/Applications/CodexBar.app/Contents/Helpers/CodexBarCLI"]
        return candidates.first { FileManager.default.isExecutableFile(atPath: $0) } ?? executable("codexbar")
    }
}
struct SetupView: View {
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) private var dismiss
    @State private var helper = false
    @State private var claude = false
    @State private var codex = false
    @State private var message: String?
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("계정 연결 도우미").font(.title2.bold())
            Text("1. 필요한 도구 설치 → 2. 본인 계정 로그인 → 3. 구독 수정에서 연결 후 조회")
                .font(.callout)
            Text("설치 확인은 로그인 성공을 뜻하지 않습니다. 실제 사용량이 표시되어야 연결이 완료됩니다.")
                .font(.caption).foregroundStyle(.secondary)
            toolRow("CodexBar 조회 도구", installed: helper,
                    address: "https://github.com/steipete/CodexBar/releases")
            toolRow("Claude Code", installed: claude, address: "https://code.claude.com/docs/en/setup")
            toolRow("Codex CLI", installed: codex, address: "https://github.com/openai/codex#quickstart")
            HStack {
                Button("설치 다시 확인") { check() }
                Spacer()
                Button("Claude 로그인") { login("Connect-Claude") }.disabled(!claude)
                Button("ChatGPT 로그인") { login("Connect-Codex") }.disabled(!codex)
            }
            Text("로그인 버튼은 터미널에서 공식 도구의 로그인을 시작합니다. 암호·인증 코드는 QuotaBar에 입력하지 않습니다. 필요한 도구를 몰래 설치하거나 계정 정보를 복사하지 않습니다.")
                .font(.caption).foregroundStyle(.secondary)
            Divider()
            Text("로그인을 마친 다음").font(.headline)
            Text("이 창 닫기 → 해당 구독 ‘수정’ → 연결 방식 ‘CodexBar 연결’ → 조회 서비스 선택 → ‘저장 및 조회’. Claude는 Claude, ChatGPT는 Work / Codex를 선택하세요.")
            Text("Claude 조회에 폴더 신뢰 설정이 필요하면 설치 안내의 ‘Claude 연결’을 따라 주세요. 일반 ChatGPT 채팅 잔여 메시지 수는 표시하지 않습니다.")
                .font(.caption).foregroundStyle(.secondary)
            if let message { Text(message).font(.caption).foregroundStyle(.orange) }
            HStack { Spacer(); Button("닫기") { dismiss() }.keyboardShortcut(.cancelAction) }
        }.padding(24).frame(width: 580)
            .onAppear { check() }
            .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in check() }
    }
    private func toolRow(_ title: String, installed: Bool, address: String) -> some View {
        HStack {
            Image(systemName: installed ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(installed ? Color.green : Color.secondary)
            Text(title)
            Spacer()
            Text(installed ? "설치 확인" : "찾지 못함").font(.caption).foregroundStyle(.secondary)
            Link("공식 설치 안내", destination: URL(string: address)!)
        }
    }
    private func check() {
        helper = ToolLocator.helper != nil
        claude = ToolLocator.executable("claude") != nil
        codex = ToolLocator.executable("codex") != nil
    }
    private func login(_ resource: String) {
        guard let url = Bundle.main.url(forResource: resource, withExtension: "command"), NSWorkspace.shared.open(url) else {
            message = "로그인 도구를 열지 못했습니다. 배포 폴더의 같은 이름 파일을 터미널에서 bash로 실행해 주세요."
            return
        }
        message = "터미널과 브라우저에서 로그인을 완료한 뒤 돌아와 주세요. 로그인만으로 구독 연결 설정이 바뀌지는 않습니다."
    }
}
