# 공개 전 출처·라이선스·이용 조건 검토

검토일: 2026-10-01. 이 문서는 현재 파일과 공식 안내를 바탕으로 한 배포 판단 기록이며, 법적 적합성을 보증하는 의견서는 아닙니다.

## CC를 붙여야 하나요?

코드에 Creative Commons(CC)를 붙일 의무는 없습니다. CC도 소프트웨어에는 소프트웨어용 라이선스를 권합니다. 이 묶음은 자체 코드와 문서에 MIT를 넣었습니다.

MIT는 무료 사용뿐 아니라 수정, 재배포, 상업적 사용도 허용하며, 저작권·라이선스 고지 유지가 조건입니다. 사용료나 등록비는 없습니다. 공개 저장소에 게시하면 이 조건으로 이용을 허락하게 됩니다. 상업적 재사용을 원하지 않는다면 게시 전에 라이선스를 다시 정해야 합니다. 브런치 글과 원본 디자인 파일은 이 저장소에 포함하지 않았으며 MIT 적용 대상에 넣지 않았습니다.

## 확인·정리한 사항

- CodexBar 제작자와 MIT 라이선스를 명시했습니다. 현재는 사용자가 별도로 설치한 도구를 호출하며 원본 코드·실행 파일을 번들에 넣지 않습니다.
- 자체 UI와 기존 조회 도구의 역할을 구분했습니다. AI의 코드 작성 도움도 명시했습니다.
- 권리 출처를 확인할 수 없는 참고 이미지·로고는 공개 묶음에서 제외했습니다. Apple/Figma 디자인 키트·폰트 원본도 포함하지 않습니다.
- 계정 파일·토큰·실제 사용자 설정을 공개 파일에 포함하지 않았습니다. 패키징은 지정된 앱·문서만 포함하도록 했습니다.
- 공식 앱, 공식 API 연동, 모든 요금제 지원, 토큰 개수 제공 등의 검증되지 않은 표현을 사용하지 않습니다.

## 남은 판단: 서비스 이용약관

오픈소스 도구를 활용할 권한과 Claude·ChatGPT 서비스에 자동 접근할 권한은 다릅니다. CodexBar가 MIT라는 이유만으로 서비스 제공자가 이 통합을 승인한 것은 아닙니다.

Anthropic 소비자 약관에는 허용되지 않은 자동 접근·데이터 수집 제한이 있습니다. OpenAI 약관에도 자동 추출·보호 조치 우회 등 제한이 있습니다. 공식 CLI가 존재한다는 사실만으로 이 제3자 주기 조회 방식까지 승인됐다고 단정할 수 없습니다. 이번 조사에서는 이 특정 통합에 대한 명시적인 허가를 확인하지 못했습니다.

따라서 공개 시 ‘비공식·실험적 연동’임을 알리고, 각 사용자의 이용 조건을 따라야 합니다. 계정 공유, 인증 정보 수집, 차단 우회, 과도한 요청을 추가하지 않습니다. 제공자의 제한 또는 변경이 확인되면 해당 연동을 중단하거나 수정해야 합니다. 확정적인 서비스 승인 여부가 필요하면 제공자에게 문의해야 하며, 이 문서의 고지가 승인을 대신하지 않습니다.

앱 이름 QuotaBar는 다른 저장소에도 존재합니다. 동일 이름 사용이 곧 침해라는 뜻은 아니지만 혼동을 줄이기 위해 저장소 이름은 `quotabar-by-cash`처럼 구분하고 제작자를 명시합니다. 상표 등록 가능성이나 전 세계 상표 충돌까지 조사한 것은 아닙니다.

## 공식 근거

- CC 소프트웨어 FAQ: https://creativecommons.org/faq/#can-i-apply-a-creative-commons-license-to-software
- MIT: https://opensource.org/license/mit
- CodexBar 라이선스: https://github.com/steipete/CodexBar/blob/main/LICENSE
- Anthropic 소비자 약관: https://www.anthropic.com/legal/consumer-terms
- OpenAI 이용약관: https://openai.com/policies/terms-of-use/
- GitHub 오픈소스 라이선스: https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/licensing-a-repository
