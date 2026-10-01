# 외부 도구·출처

## CodexBar

- 원 프로젝트: https://github.com/steipete/CodexBar
- 제작자: Peter Steinberger 및 기여자
- 현재 확인한 라이선스: MIT, Copyright (c) 2026 Peter Steinberger
- 원문: https://github.com/steipete/CodexBar/blob/main/LICENSE
- CLI 인터페이스 참고: https://github.com/steipete/CodexBar/blob/main/docs/cli.md

QuotaBar는 별도로 설치된 CodexBar CLI에 `usage --provider claude|codex --source cli --format json`을 요청하고 응답을 해석합니다. 이 배포 폴더에는 CodexBar 소스·바이너리를 포함하지 않습니다. 사용량 조회를 자체 개발한 것처럼 소개하지 않습니다.

향후 CodexBar 코드나 실행 파일을 포함한다면 해당 배포 버전의 MIT 저작권·허가 문구를 함께 보존하고, 그 안의 의존성 라이선스도 확인해야 합니다. 이 고지만으로 모든 재배포 조건이 충족되는 것은 아닙니다.

## 공식 계정 도구

- Claude Code: https://code.claude.com/docs/en/setup — 사용자 별도 설치·로그인. Anthropic의 해당 이용약관 적용.
- Codex CLI: https://github.com/openai/codex — 사용자 별도 설치·로그인. 원 프로젝트 라이선스와 OpenAI 계정 이용약관은 별개.

공식 도구와 해당 인증 정보는 번들에 포함하지 않습니다. 로그인 버튼은 공식 명령을 터미널에서 시작합니다. 외부 도구의 라이선스를 QuotaBar의 MIT로 바꾸지 않습니다.

## 디자인과 명칭

공개용 버전에서는 개인 사용 버전의 참고 이미지와 잘라낸 Claude/ChatGPT 로고를 제거했습니다. 문자 아이콘과 macOS 기본 UI를 사용하며 Apple 디자인 시스템 파일, 폰트 파일, 원본 PNG/SVG를 배포하지 않습니다. 시스템 폰트·시스템 심벌은 macOS 런타임에서 사용합니다.

Claude, ChatGPT, Codex, macOS 등의 이름은 연동 대상을 설명하기 위한 것이며 각 권리자의 상표입니다. 공식 제휴·보증을 뜻하지 않습니다. QuotaBar라는 이름은 다른 프로젝트에서도 사용 중이며, 이 프로젝트와 무관합니다.

## 제작

구지원(Cash): 목적 정의, UX/UI 결정, 실제 맥에서 설치·사용 확인.
ChatGPT: 코드 작성·수정·문서 정리 지원.
본 저장소의 자체 코드·문서에 적용되는 라이선스는 LICENSE를 확인하세요.
