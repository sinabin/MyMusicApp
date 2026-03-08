# CLAUDE.md

## Coding Convention

### Dart 주석 스타일

- `///` 문서 주석을 사용한다. (`/** */` 사용 금지)
- 종결어미는 명사형으로 통일한다. (`~반환.`, `~삭제.`, `~추가.`)
  - 좋은 예: `/// 저장된 모든 항목을 최신순으로 반환.`
  - 나쁜 예: `/// 저장된 모든 항목을 최신순으로 반환한다.`
- 첫 문장은 마침표로 끝나는 한 줄 요약으로 작성한다.
- 부가 설명이 필요한 경우 빈 `///` 줄 후에 작성한다.
- 파라미터/클래스 참조는 `[paramName]`, `[ClassName]` 대괄호를 사용한다. (`@param` 사용 금지)
- 사용법 예시(코드 블록)는 주석에 포함하지 않는다.
- 이름만으로 의미가 충분한 경우에도 최소한 한 줄 요약은 작성한다.
- 클래스 주석에는 역할과 관련 클래스 간의 관계를 명시한다.

## Flutter UI 제스처 설계 원칙

- `GestureDetector`로 넓은 영역을 감쌀 때, 내부에 `IconButton`·`InkWell` 등 자체 탭 핸들러를 가진 위젯이 있으면 **제스처 경쟁(gesture arena)** 이 발생하여 양쪽 모두 동작하지 않을 수 있다.
- **탭 영역을 분리**한다: 네비게이션용 탭 영역과 액션 버튼 영역을 같은 `GestureDetector`로 감싸지 않는다.
  - 나쁜 예: `GestureDetector(onTap: navigate, child: Row([thumbnail, text, IconButton, IconButton]))`
  - 좋은 예: `Row([Expanded(GestureDetector(onTap: navigate, child: Row([thumbnail, text]))), IconButton, IconButton])`
- 빈 영역도 탭을 감지해야 하면 `behavior: HitTestBehavior.opaque`를 명시한다.
- 코드 작성 시 **먼저 위젯 트리 내 제스처 핸들러 중첩 여부를 확인**한 뒤 구현한다.

## Git 관리

- 새로 생성한 파일은 `git add`를 실행하여 추적 대상에 포함시킨다.
- 기존 파일 수정 시에도 변경 사항을 스테이징한다.
