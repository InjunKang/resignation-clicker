# 사직서 던지기! 대리님 키우기

대한민국 직장인 대리 만족 컨셉의 방치형(idle/incremental) 클리커 게임.
Godot 4.7 (GDScript)로 제작, 웹(HTML5)으로 export.

## 실행 방법

### 1. Godot 설치

Godot 4.7 이상이 필요합니다 (winget으로 설치했다면 이미 되어 있음):

```
winget install --id GodotEngine.GodotEngine -e
```

웹 export를 하려면 Export Templates도 필요합니다. Godot 에디터를 열고
`Editor > Manage Export Templates`에서 현재 버전과 일치하는 템플릿을
다운로드하세요.

### 2. 에디터에서 열기

Godot 에디터를 실행하고 이 폴더(`project.godot`가 있는 위치)를 프로젝트로
열면 됩니다. 플레이 버튼(F5)으로 바로 실행해서 확인할 수 있습니다.

### 3. 웹으로 export

에디터 메뉴 `Project > Export`에서 이미 설정된 "Web" 프리셋으로 export
하거나, 커맨드라인으로:

```
godot --headless --path . --export-release "Web" export/web/index.html
```

Godot 웹 빌드는 `file://`로 직접 열면 CORS 문제로 동작하지 않습니다.
반드시 HTTP 서버로 서빙해야 합니다:

```
cd export/web
python -m http.server 8765
# 브라우저에서 http://localhost:8765 접속
```

저장 데이터는 브라우저의 IndexedDB에 영속되므로(Godot 웹 export의
`user://` 매핑), 같은 브라우저·같은 origin으로 다시 접속하면 이어서
플레이됩니다.

## 프로젝트 구조

```
scripts/
  autoload/
    GameData.gd     # 정적 데이터: 스테이지/몹/보스/장비/동료/스킬/재화 테이블
    GameState.gd     # 런타임 상태: 재화, 능력치, 장비, 스테이지 진행, 저장용 직렬화
    SaveManager.gd   # 저장/불러오기, 오프라인 보상 계산
  battle_view.gd     # 전투 화면 (자동 공격, 보스전, 스킬, 타격감 연출)
  main.gd            # 루트 UI 조립 (상단바/전투화면/탭메뉴/하단패널)
  top_bar.gd, tab_menu.gd
  ui/
    stock_chart.gd   # 재테크 탭용 커스텀 라인 차트
    panels/          # 업무/장비/결사대/재테크/뽑기/사직서/업적 탭 패널
  util/fmt.gd        # 숫자 축약 표시 (1234 -> "1.23K")
assets/fonts/        # Pretendard(한글) + Noto Emoji(이모지 fallback), 둘 다 OFL
docs/superpowers/specs/  # 설계 문서 (Phase별)
```

UI는 전부 `.tscn` 씬 파일 대신 GDScript 코드로 직접 조립합니다(`Main.tscn`은
루트 Control 하나만 있고, 나머지는 `_ready()`에서 `add_child()`로 구성). 이
프로젝트는 Godot 에디터 GUI 조작 없이(에이전트가 텍스트만으로) 만들어졌기
때문입니다.

## 현재 구현 범위

- 3개 회사(스테이지 1~3) × 10서브스테이지, 각 회사 고유 보스
- 능력치 4종(타자속도/멘탈/아부력/월급루팡), 장비 4종 무제한 강화
- 사내 비밀 결사대 5종(자동 해금, DPS + 패시브)
- 액티브 스킬 4종(자동/수동 발동 전환 가능)
- 재테크(가짜 주식 2종, 실시간 가격 차트), 뽑기(천장 시스템 포함)
- 사직서 던지기(프레스티지) — 진행 초기화 + 영구 업그레이드
- 업적 8종(평생 누적, 프레스티지에도 유지)
- 오프라인 보상 + 전투 상태와 무관한 패시브 골드 수입(소프트락 방지)

## 알려진 제한사항 / 다음 단계

- 비주얼은 전부 이모지+텍스트 플레이스홀더(실제 아트 에셋 없음)
- 사운드 없음
- 밸런스는 그리디 자동 강화 시뮬레이션으로 검증했으나, 실제 플레이 패턴
  기준 파인튜닝은 아직 안 함
- 뽑기 등급 연출(파티클 등), 재테크 이벤트 뉴스 텍스트 등은 미구현
