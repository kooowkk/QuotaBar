# 지원님용 GitHub 공개 안내 — 무료로 진행하기

이 문서는 비개발자도 브라우저와 맥 터미널로 따라 할 수 있게 작성했습니다.

## 먼저 구분할 두 파일

| 파일 | 용도 |
|---|---|
| 지금 받은 `QuotaBar-GitHub-Source.zip` | GitHub에 올릴 소스·문서. 아직 완성 앱이 들어 있지 않음 |
| 나중에 맥에서 만드는 `QuotaBar-0.2.0-beta.1-macOS-universal.zip` | 친구가 내려받을 완성 앱. 외부 도구 설치·본인 계정 연결은 별도 |

소스만 올려도 프로젝트 공개는 가능합니다. 친구에게 개발 도구 없이 앱을 주려면 아래 2~3단계를 완료해야 합니다.

## 1. 압축 풀기

1. `QuotaBar-GitHub-Source.zip`을 다운로드해 더블클릭합니다.
2. 생성된 `QuotaBar-Public` 폴더를 엽니다.
3. `README.md`, `LICENSE`, `Sources`, `Resources`, `Tests`, `docs`, `scripts`, `Install.command`, `Build-Release.command`가 있는지 봅니다.
4. 기존 개인용 QuotaBar 폴더와 합치지 말고 별도 폴더로 둡니다.

## 2. 지원님 맥에서 새 버전 확인하기

1. 현재 메뉴바 QuotaBar를 열고 `구독 관리·설정 → QuotaBar 종료`를 누릅니다.
2. `Command + Space`를 누르고 `터미널`을 검색해 엽니다.
3. 터미널에 아래 글자만 입력합니다. **뒤에 공백 한 칸**을 넣고 아직 Enter를 누르지 않습니다.

```text
bash 
```

4. 새 폴더의 `Install.command`를 터미널로 드래그합니다. 실제 파일 경로가 자동으로 붙습니다.
5. Enter를 누릅니다. 개발 도구 설치 안내가 나오면 설치를 마친 뒤 같은 방법으로 다시 실행합니다.
6. 검사·컴파일이 끝나고 앱이 뜨는지 확인합니다. 기존 설정·계정은 복사하거나 지우지 않으며 이전 앱은 백업으로 남습니다.
7. 설정의 `연결 도우미`를 열어 도구 탐지와 로그인 버튼을 확인합니다. 이미 로그인돼 있다면 다시 로그인할 필요는 없습니다.
8. 기존 Claude/ChatGPT 값, 리셋 문구, 5분 조회를 확인합니다. 세부 목록은 `docs/RELEASE-CHECKLIST.md`에 있습니다.

에러가 발생하면 아직 릴리스를 게시하지 말고 오류를 확인하세요. 새 코드는 여기 제작 환경에서 맥용 컴파일을 실행하지 못했기 때문에 이 단계가 필요합니다.

## 3. 친구에게 줄 완성 앱 ZIP 만들기

1. 터미널에 다시 `bash `를 입력합니다.
2. `Build-Release.command`를 드래그하고 Enter를 누릅니다.
3. Apple Silicon·Intel 코드를 함께 빌드하므로 설치보다 시간이 더 걸릴 수 있습니다.
4. 완료되면 `dist` 폴더가 열립니다. 아래 두 파일을 사용합니다.
   - `QuotaBar-0.2.0-beta.1-macOS-universal.zip`
   - `QuotaBar-0.2.0-beta.1-macOS-universal.zip.sha256`
5. ZIP을 직접 풀어 앱을 실행해 봅니다. 테스트 전에는 설치된 QuotaBar를 종료해 중복 실행하지 않습니다.

`.sha256`은 다운로드 파일이 같은지 확인하는 값입니다. 친구가 앱을 사용하는 데 직접 열 필요는 없습니다.

이 과정은 지원님 맥에서 진행합니다. 유료 Apple 개발자 등록, 서버, GitHub Actions를 사용하지 않습니다. 개인 설정·계정 파일은 포함하지 않습니다. 앱은 공증되지 않았으므로 다른 맥에서 보안 경고가 발생할 수 있습니다.

## 4. GitHub 저장소 만들기

1. https://github.com 에서 로그인합니다.
2. 오른쪽 위 `+ → New repository`를 누릅니다. 또는 https://github.com/new 로 이동합니다.
3. Repository name: `quotabar-by-cash`처럼 입력합니다. QuotaBar라는 이름의 다른 프로젝트와 구분하기 위한 예시입니다.
4. Description: `Claude와 ChatGPT 계정 사용 한도를 한눈에 확인하는 macOS 메뉴바 앱`.
5. 공개하려면 **Public**을 선택합니다.
6. README 자동 추가는 켜지 않습니다. `.gitignore`와 License 선택 항목은 `None`으로 둡니다. 다운로드한 폴더에 이미 준비돼 있습니다.
7. `Create repository`를 누릅니다.

라이선스를 선택하지 말라는 뜻은 ‘라이선스 없이 공개하라’가 아니라 준비된 MIT LICENSE 파일을 그대로 올리라는 뜻입니다.

## 5. 소스 코드 올리기

1. 빈 저장소 화면의 `uploading an existing file` 링크를 누릅니다. 파일이 이미 있다면 `Add file → Upload files`를 사용합니다.
2. Finder에서 `QuotaBar-Public` 폴더 **안으로 들어갑니다**.
3. 아래 파일·폴더를 브라우저 업로드 영역으로 드래그합니다.
   - `README.md`, `LICENSE`, `THIRD_PARTY_NOTICES.md`, `PRIVACY.md`, `CHANGELOG.md`, `VERSION`
   - `Install.command`, `Build-Release.command`
   - `Sources`, `Resources`, `Tests`, `scripts`, `docs`
   - `.gitignore` (Finder에서 `Command + Shift + .`로 표시할 수 있습니다.)
4. **`build`, `dist`, 기존 계정·설정 파일은 올리지 않습니다.** `.gitignore`가 있더라도 브라우저에서 직접 드래그한 파일을 대신 걸러 준다고 생각하지 마세요.
5. 업로드 목록에 `Sources/QuotaBar.swift`처럼 표시되는지 확인합니다. `QuotaBar-Public/Sources/…`처럼 전체가 한 폴더 안에 들어가면 저장소 첫 화면의 README가 보이지 않을 수 있습니다. 폴더 안 내용물을 올리세요.
6. Commit message에 `Prepare QuotaBar public beta`를 입력합니다.
7. 새 저장소라면 기본 브랜치에 커밋하는 옵션으로 `Commit changes`를 누릅니다. 기존 보호 브랜치에서는 새 브랜치/PR 절차가 필요할 수 있습니다.
8. 저장소 첫 화면에 README 설명이 나타나는지 확인합니다. 파일 목록에 LICENSE도 있어야 합니다.

이 프로젝트는 100개 미만의 작은 텍스트 파일로 구성돼 브라우저 업로드 범위 안에 있습니다. GitHub 공식 안내는 브라우저 업로드 파일당 25 MiB, 한 번에 100개까지입니다.

`.gitignore`를 못 올렸다면 `Add file → Create new file`에서 파일 이름을 `.gitignore`로 입력하고 내려받은 동일 파일의 내용을 붙여 넣어 저장할 수 있습니다.

## 6. 친구가 받을 앱을 Releases에 올리기

소스 코드를 올리는 것과 다운로드할 앱을 올리는 것은 별도입니다. 3단계에서 실제로 앱 ZIP을 만든 후 진행합니다.

1. 저장소의 `Releases`를 누릅니다. 보이지 않으면 저장소 주소 끝에 `/releases`를 붙입니다.
2. `Create a new release` 또는 `Draft a new release`를 누릅니다.
3. Tag에 `v0.2.0-beta.1`을 입력하고 새 태그를 생성합니다.
4. Target은 방금 코드를 올린 기본 브랜치(보통 `main`)로 둡니다.
5. Release title은 `QuotaBar 0.2.0 beta 1`로 입력합니다.
6. 설명은 `docs/RELEASE-NOTES.md`를 참고해 작성합니다. 실제 테스트한 맥·OS·외부 도구 버전만 적으세요.
7. 파일 첨부 영역에 3단계의 **앱 ZIP과 sha256**을 올립니다. `QuotaBar-GitHub-Source.zip`을 앱이라고 올리면 안 됩니다.
8. `Set as a pre-release` 옵션을 선택합니다. 아직 테스트 중인 버전임을 표시합니다.
9. 첨부 파일과 안내를 확인하고 `Publish release`를 누릅니다. 테스트가 끝나지 않았다면 `Save draft`로 저장할 수 있습니다.
10. 공개 페이지의 Assets에서 직접 앱 ZIP을 다운로드할 수 있는지 확인합니다.

GitHub가 자동 생성한 `Source code (zip)`과 `Source code (tar.gz)`는 완성 앱이 아닙니다. 친구에게는 직접 첨부한 `…macOS-universal.zip`을 안내하세요.

## 7. 친구에게 전달할 내용

릴리스 페이지 주소를 보내고 다음 내용을 함께 알려 주세요.

- 맥용이며 macOS 14 이상이 필요함.
- Assets의 `QuotaBar-…-macOS-universal.zip` 다운로드.
- 압축을 풀고 앱을 응용 프로그램 폴더에 넣어 실행.
- 무료 비공증 배포본이므로 첫 실행 보안 확인이 필요할 수 있음.
- 설정의 연결 도우미에서 필요한 도구를 설치하고 본인 계정으로 로그인.
- 일반 ChatGPT 채팅 잔여 메시지 수가 아닌 Claude/Codex 계정 사용 한도를 표시함.
- 로그인 정보나 인증 코드를 제작자에게 보낼 필요가 없음.

첫 테스트는 가능하면 지원님의 기존 계정·개발 도구가 없는 별도 맥 또는 별도 macOS 사용자에서 진행하세요. 설치가 쉬워졌는지 확인하는 가장 직접적인 방법입니다.

## 8. 다음 버전을 올릴 때

코드만 바꾸고 이전 앱 ZIP을 그대로 두면 친구는 이전 버전을 받습니다. 코드 수정 → VERSION과 앱 빌드 번호 수정 → 맥 테스트 → Build-Release.command → 새 태그·새 Release 순서로 진행하세요. 현재 자동 업데이트 기능은 없으므로 사용자가 새 앱을 받아 교체해야 합니다.

## 비용과 권리

MIT LICENSE는 등록비 없는 이용 허락 문서입니다. 다른 사람의 상업적 재사용도 허용하므로 게시 전에 조건을 읽어 주세요. CodexBar 출처를 지우지 마세요. 공식 서비스의 자동 조회 허용 여부는 MIT와 별개입니다. `docs/RIGHTS.md`에 검토 결과를 적었습니다.

## 공식 참고 문서

- 파일 업로드: https://docs.github.com/en/repositories/working-with-files/managing-files/adding-a-file-to-a-repository
- 릴리스 만들기: https://docs.github.com/en/repositories/releasing-projects-on-github/managing-releases-in-a-repository
- macOS 실행 경고: https://support.apple.com/102445
