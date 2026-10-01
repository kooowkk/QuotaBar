# QuotaBar 설치·계정 연결

macOS 14 이상에서 사용합니다. Windows·iPhone용 앱이 아닙니다. 이 안내는 0.2.0-beta.1 기준입니다.

## A. 미리 만들어진 앱을 받은 경우

1. `QuotaBar-…-macOS-universal.zip`의 압축을 풉니다.
2. 기존 QuotaBar가 실행 중이라면 설정에서 종료합니다.
3. `QuotaBar.app`을 기존 앱 위치에 넣습니다. 처음 설치한다면 Finder의 응용 프로그램 폴더에 넣습니다. 기존 소스 설치 사용자는 홈 폴더의 `Applications`에 앱이 있을 수 있습니다. 두 위치에 중복 설치하지 마세요.
4. 앱을 실행합니다. 독(Dock)에 일반 창이 뜨지 않아도 상단 메뉴바에 `구독`이 생기면 실행된 것입니다.
5. `구독 → 구독 관리·설정 → 연결 도우미`에서 B를 진행합니다.

### ‘확인되지 않은 개발자’ 경고가 나오면

이 무료 배포본에는 Apple Developer ID 서명·공증이 없습니다. 직접 신뢰하는 저장소에서 받은 파일인지 확인하고, macOS가 제공하는 `시스템 설정 → 개인정보 보호 및 보안 → 그래도 열기` 절차를 이용하세요. 표시되는 버튼은 OS 버전·관리 정책에 따라 다를 수 있습니다.

공식 안내: https://support.apple.com/102445

‘악성 코드’, ‘손상된 앱’ 등 다른 종류의 경고라면 강제로 우회하지 말고 다운로드 출처와 파일을 다시 확인하세요. 시스템 보안을 전체 해제하는 명령은 제공하지 않습니다. 회사 관리 맥에서는 조직 정책으로 실행이 제한될 수 있습니다.

## B. 필요한 도구와 계정 연결

### 1. CodexBar 조회 도구 설치 — 공통

https://github.com/steipete/CodexBar/releases 에서 macOS 앱 ZIP을 받습니다. 이름에 `dSYM`이 있는 파일과 Linux 파일은 선택하지 않습니다. 압축을 풀고 `CodexBar.app`을 응용 프로그램 폴더에 넣습니다. QuotaBar는 안에 들어 있는 `CodexBarCLI`를 호출합니다. CodexBar 메뉴를 계속 열어둘 필요는 없습니다.

연결 도우미에서 `설치 다시 확인`을 눌러 주세요. 표시가 ‘설치 확인’으로 바뀌어도 계정 로그인은 별도로 해야 합니다.

### 2. Claude 연결

1. 연결 도우미의 Claude Code `공식 설치 안내`를 엽니다: https://code.claude.com/docs/en/setup
2. 공식 안내에 따라 Claude Code를 설치합니다. API 구매가 아닌 본인 구독 계정으로 연결합니다.
3. QuotaBar의 `설치 다시 확인` → `Claude 로그인`을 누릅니다.
4. 터미널에서 공식 `claude auth login`이 시작됩니다. 브라우저에서 본인 계정으로 로그인합니다. QuotaBar는 암호를 받지 않습니다.
5. 조회 단계에서 폴더 신뢰 설정이 필요하다면 터미널에서 아래를 실행합니다. **Claude 채팅 입력란이 아니라 `%` 또는 `$`가 보이는 일반 터미널**에 붙여넣으세요.

```bash
export PATH="$HOME/.local/bin:/opt/homebrew/bin:/usr/local/bin:$PATH"
mkdir -p "$HOME/QuotaBar-Connect"
cd "$HOME/QuotaBar-Connect"
claude
```

`Accessing workspace` 경로가 방금 만든 `QuotaBar-Connect` 폴더인지 확인합니다. 이 전용 폴더를 신뢰할지 직접 선택하세요. 홈 폴더 전체를 신뢰하도록 안내하는 것이 아닙니다. 테마 등 초기 설정 후 `/usage`로 사용량을 확인하고 `/exit`로 나옵니다. 모델에 작업을 시키는 프롬프트를 보낼 필요는 없습니다.

6. QuotaBar 설정에서 Claude `수정` → 연결 방식 `CodexBar 연결` → 조회 서비스 `Claude` → `저장 및 조회`.

### 3. ChatGPT / Codex 연결

1. 연결 도우미에서 Codex CLI의 `공식 설치 안내`를 엽니다: https://github.com/openai/codex#quickstart
2. 공식 안내대로 Codex CLI를 설치합니다. Homebrew는 여러 선택지 중 하나로 필수가 아닙니다.
3. `설치 다시 확인` → `ChatGPT 로그인`을 누릅니다. 터미널의 `codex login`이 공식 로그인 절차를 시작합니다.
4. 본인 ChatGPT 구독 계정으로 로그인합니다. API 키 구매·입력이 목적이 아닙니다.
5. QuotaBar 설정에서 ChatGPT `수정` → 연결 방식 `CodexBar 연결` → 조회 서비스 `ChatGPT · Work / Codex` → `저장 및 조회`.

예전 설정을 유지한 사용자는 조회 서비스가 Claude로 남아 있지 않은지 확인하세요. 기존에 사용자가 지정한 설정은 자동으로 덮어쓰지 않습니다.

### 로그인 버튼이 작동하지 않는 경우

소스 폴더의 `Resources/Connect-Claude.command` 또는 `Resources/Connect-Codex.command`를 터미널에서 실행할 수 있습니다. `bash `를 입력하고 해당 파일을 드래그한 뒤 Enter를 누르세요. 이 파일들은 공식 도구 로그인만 시작하며 외부 도구를 자동 설치하지 않습니다.

## C. 소스 코드로 설치하는 경우

1. GitHub의 `Code → Download ZIP`을 받고 압축을 풉니다.
2. 기존 QuotaBar 설정에서 `QuotaBar 종료`를 누릅니다.
3. `Install.command`를 실행합니다. 실행이 어렵다면 터미널에 `bash `를 입력합니다. **bash 뒤에 공백 한 칸**을 넣습니다.
4. Finder에서 `Install.command`를 터미널로 드래그하고 Enter를 누릅니다.
5. Apple Command Line Tools 설치가 뜨면 완료 후 3~4번을 반복합니다.
6. 계산 검사와 빌드가 끝나면 `~/Applications/QuotaBar.app`에 설치되고 실행됩니다.

관리자 권한이나 유료 개발자 등록은 사용하지 않습니다. 기존 앱은 날짜가 붙은 백업으로 남기고 설정·로그인 정보는 유지합니다. 이 버전의 문자 아이콘은 공개용으로 변경한 것이며 오류가 아닙니다.

## D. 자주 겪는 문제

- **아무 창도 안 열림:** 메뉴바 앱입니다. 상단 `구독` 아이콘을 확인하세요. 아이콘이 없다면 활동 상태 보기에서 QuotaBar가 실행 중인지 확인합니다.
- **재부팅 후 안 보임:** 앱을 한 번 열고 설정의 `맥에 로그인하면 자동 실행`을 켭니다. macOS 로그인 항목에서도 허용되어 있어야 합니다.
- **도구를 못 찾음:** 표준 검색 위치는 `~/.local/bin`, `/opt/homebrew/bin`, `/usr/local/bin`, 앱이 전달받은 PATH입니다. 터미널 전용 가상환경에만 설치했다면 Finder에서 실행한 앱이 찾지 못할 수 있습니다.
- **조회 실패:** 설정의 오류 설명을 확인합니다. 설치 확인과 로그인 확인은 별개입니다. 계정 만료, 폴더 신뢰, 외부 도구 변경, 네트워크 문제일 수 있습니다. 로그인 버튼으로 다시 연결해 보세요.
- **No available fetch strategy:** 해당 도구의 CLI 조회가 사용 가능한지 확인해야 합니다. Claude는 `claude auth status`로 로그인 상태를 확인할 수 있습니다. 개인 정보가 나올 수 있으므로 결과 전체를 공개하지 마세요.
- **키체인 암호 요청:** QuotaBar는 브라우저 쿠키 가져오기를 사용하지 않습니다. 다른 도구의 키체인 접근 요청이라면 요청 앱과 목적을 확인하세요. 비밀번호·키체인 파일을 개발자에게 보내지 마세요.
- **5분이 지나도 값이 같음:** 실제 사용량이 바뀌지 않았을 수 있습니다. 설정의 조회 완료 시각·실패 항목, 카드 툴팁의 데이터 시각을 함께 확인하세요. 잠자기·앱 종료 중에는 조회하지 않습니다.
- **GitHub 오류 제보:** OS 버전, 앱 버전, 도구 버전, 오류 문구만 적어주세요. 이메일, 로그인 URL, 인증 코드, 토큰은 가려 주세요.

## E. 삭제

설정에서 자동 실행을 끄고 앱을 종료한 뒤 앱 파일을 삭제합니다. 설정까지 삭제하려면 Finder `이동 → 폴더로 이동`에 `~/Library/Application Support/QuotaBar`를 입력해 해당 폴더만 삭제합니다. 수동으로 추가한 API 토큰은 키체인 접근 앱의 `local.quotabar.token` 항목에서 관리합니다. Claude/Codex 로그인 정보는 각 공식 도구에서 별도로 로그아웃해야 합니다.
