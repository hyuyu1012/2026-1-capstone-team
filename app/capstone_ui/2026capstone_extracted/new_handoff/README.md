# 안심 케어 — 홈 / 기록 화면 핸드오프

이 폴더는 **홈 화면**과 **기록 화면** 두 개를 본 앱에 옮기는 데 필요한 모든 정보입니다. 코드는 그대로 가져다 쓰는 게 아니라, 타겟 코드베이스의 컴포넌트 라이브러리·아키텍처로 다시 구현하기 위한 **단일 소스 오브 트루스**입니다.

```
handoff/
├── README.md
├── screenshots/
│   ├── 1-home.png      ← 홈 화면 전체 (스크롤 없이 한 장)
│   └── 2-records.png   ← 기록 화면 전체
└── source/
    ├── prototype/
    │   ├── home.jsx       ← 홈 + 그 안 컴포넌트들
    │   ├── records.jsx    ← 기록 + 달력
    │   └── shared.jsx     ← 공유 데이터, 아이콘, BottomNav, TopBar, 더미 데이터
    └── wanted/
        └── colors_and_type.css  ← 디자인 토큰 (색·타입·간격)
```

---

## 🎯 두 화면이 공유하는 비주얼 시스템

### 페이지 구조
- 좌우 padding **24px**, 카드 가로 폭은 그 안에서 가득
- 카드 padding `20px 18px`, radius **16**, 1px `--line-normal-neutral` border, 그림자 없음
- 리스트 컨테이너 radius **14**, 그 안의 row 들은 첫 row 빼고 위쪽 1px hairline 으로 분리
- 카드 간 세로 gap **20px**, 큰 섹션 사이 **24~28px**

### 색 (전부 `source/wanted/colors_and_type.css` 에 정의)
| 토큰 | 값 | 역할 |
|---|---|---|
| `--primary-normal` | #0066FF | "완료" 상태 한 가지 |
| `--label-strong` | rgba(23,23,25,1) | h1·강조 본문 |
| `--label-normal` | rgba(46,47,51,0.88) | 본문 |
| `--label-neutral` | rgba(55,56,60,0.61) | 서브 텍스트 |
| `--label-alternative` | rgba(55,56,60,0.28) | 캡션 |
| `--line-normal-neutral` | rgba(112,115,124,0.16) | 카드 외곽선 |
| `--line-normal-normal` | rgba(112,115,124,0.22) | 버튼/입력 외곽선 |
| `--fill-alternative` | rgba(112,115,124,0.05) | 트랙 |
| `--c-red-60` | #FF6363 | 기록의 "누락" 상태 |
| 페이지 배경 | #F4F5F7 | |

색은 **검정/회색 + 파랑(완료) + 빨강(누락)** 세 가지만 씁니다. 카테고리별 컬러 코딩 없음.

### 타이포 (`--font-sans` Pretendard, `--font-display` Wanted Sans Variable)
- 페이지 헤더 h1 — 28px / weight 700 / `-0.028em` / `--label-strong`
- 섹션 캡스 라벨 — 11.5px / 700 / `letter-spacing: 0.1em` / uppercase / `--label-neutral`
- 카드 row 본문 — 14.5px / 500 / `--label-strong`
- 카드 row 서브(시간 등) — 11.5px / 500 / `--label-alternative`, `font-variant-numeric: tabular-nums`
- 카운트 / 시각 우상단 — 14px / 700 / `--label-strong` 또는 `--label-alternative`
- 숫자는 항상 `tabular-nums`

---

## 1. 홈 화면 (`screenshots/1-home.png`, `source/prototype/home.jsx`)

### 화면 구성 (위→아래)

#### 1-1. 페이지 헤더
- h1 **"오늘 현황을 확인하세요"**
- 서브 **"어머니 · 이순자"** (관계 · 환자 이름, 13.5px / 500 / `--label-neutral`)

#### 1-2. 오늘 일정 카드
- 캡스 라벨 **"오늘 일정"**
- 그 아래 6칸 grid (`gridTemplateColumns: repeat(6, 1fr)`, gap 8px)
- 셀: aspect-ratio 1:1, radius **8**, transition 150ms
- 완료 셀: `--primary-normal` 채움, 흰 약/식사 아이콘, `box-shadow: 0 2px 6px rgba(0,102,255,0.18)`
- 미완료 셀: 흰 배경, 1.5px `--line-normal-normal` border, 회색 아이콘
- 약 아이콘 / 식사 아이콘 inline SVG (home.jsx 의 `TodayGrid` 안)
- **탭하면 완료 ↔ 미완료 토글**, 동일한 약 인스턴스의 takenAt 도 같이 업데이트

#### 1-3. 복용 일정 리스트
- 캡스 라벨 **"복용 일정"** + 우상단 `{완료} / {전체}` 카운트 (14px / 700 / `--label-alternative`)
- 카드 컨테이너 안에 row 6개

**Row 구조** (오른쪽 박스 외곽선 없는 체크리스트 스타일):
```
[O 체크박스]  [이름                ]
              [예정시각 → 실제시각]
```
- padding `11px 18px`, 첫 row 빼고 위쪽 1px hairline
- 체크박스: 22×22 circle
  - 완료: `--primary-normal` 채움 + 흰 ✓ (stroke 3, width 12)
  - 미완료: transparent + 1.5px `--line-normal-normal` border
- 이름: 14.5px / 500
  - 완료: 색 `--label-alternative`, `text-decoration: line-through` (color rgba(55,56,60,0.32), thickness 1px)
  - 미완료: 색 `--label-strong`
- 시각 라인 (이름 아래 2px gap): 11.5px / 500 / `--label-alternative`, `tabular-nums`
  - 미완료: `08:00` — 예정 시각만
  - 완료: `08:00 → 08:12` — 예정 시각 + 화살표 + 실제 시각, 실제 시각은 `--primary-normal` / weight 600
- **전체 row 가 클릭 가능** — 탭하면 완료 토글

### 더미 데이터 모델
```js
// source/prototype/shared.jsx 의 INITIAL_TODAY
{
  id: string,
  kind: 'med' | 'meal',
  name: string,          // 예: '암로디핀 5mg', '아침 식사'
  dose?: string,         // 약일 때 '1정'
  time: string,          // "HH:mm" 예정 시각
  taken: boolean,
  takenAt?: string       // 완료 시각 "HH:mm"
}
```

---

## 2. 기록 화면 (`screenshots/2-records.png`, `source/prototype/records.jsx`)

### 화면 구성

#### 2-1. 페이지 헤더
- h1 **"복용 기록을 확인하세요"**, 서브 동일

#### 2-2. 월 달력 카드
- 헤더 (양옆 ◀ ▶ + 가운데 "2026년 5월" 14px / 700)
- 요일 헤더 7칸 — 일(`--status-cautionary`), 평일(`--label-alternative`)
- 7×6 grid (gap 4px)
- 각 셀: aspect 1:1, radius **8**, 폰트 13/600~700
- **완료율로 셀 배경 보간** (단일 색 계조):
  - `null` 또는 미래 → transparent
  - `0` → transparent
  - `0 < v ≤ 0.34` → `rgba(0,102,255,0.18)`
  - `0.34 < v ≤ 0.67` → `rgba(0,102,255,0.40)`
  - `0.67 < v < 1` → `rgba(0,102,255,0.68)`
  - `v === 1` → `--primary-normal` 채움
  - 0.5 초과 셀은 숫자 색이 흰색이 되도록 (가독성)
- 오늘 셀 = 1.5px `--label-strong` border
- 선택 셀 = 2px `--label-strong` border
- 미래 셀 disabled (pointer-events none)
- 카드 하단 범례: "적음 ─ □□□□ ─ 많음" (4단계 색 견본)

#### 2-3. 선택된 날 헤더
한 줄, baseline 정렬, padding `0 4px`:
- 좌측: **"5월 27일 수요일"** (14px / 700 / `--label-strong` / `tabular-nums`), 오늘이면 옆에 파란 **"오늘"** 라벨 (14px / 700 / `--primary-normal`, margin-left 8)
- 우측: **"{완료} / {전체}"** (14px / 700 / `--label-alternative`)

#### 2-4. 그 날 일정 리스트
홈과 똑같은 체크리스트 row 패턴이지만 **누락 상태가 추가**됨:

| 상태 | 체크박스 | 이름 색 | 시각 라인 |
|---|---|---|---|
| 완료 | 파란 채움 ✓ | 회색 + 취소선 | `08:00 → 08:12` (실제는 파랑) |
| 누락 | 빨간 외곽 ✕ (1.5px `--c-red-60`) | `--label-strong` | `12:30  누락` (누락 라벨 `--c-red-60` / 700) |

- 누락 X 아이콘: stroke 3, 빨간 색
- 누락 시 row 자체 배경은 그대로 (색만 빨간 외곽 체크 + 빨간 "누락" 텍스트로 표시)

### 더미 데이터
- `MONTH_DATA: (number|null)[]` 길이 31, 각 일의 완료율 (0~1), 미래 = null
- 날 클릭 시 `generateDay(date)` 가 `ScheduleItem[]` 반환 (해당 날짜의 약/식사 + taken/takenAt)

---

## ⚙️ 인터랙션

| 화면 | 인터랙션 |
|---|---|
| 홈 | 6칸 셀 탭 → 완료 토글 (즉시) |
| 홈 | row 탭 → 완료 토글 (즉시) |
| 기록 | 달력 셀 탭 → 아래 상세 리스트가 그 날 데이터로 즉시 교체 |
| 기록 | 미래 셀 비활성 (`disabled`, pointer-events none) |
| 기록 | ◀ ▶ 월 이동 (UI 만, 데이터는 단일 월) |

모든 트랜지션 150~180ms, ease `cubic-bezier(0.2, 0, 0, 1)`.

---

## 🧱 컴포넌트 매핑 (구현 시 참고)

`source/prototype/home.jsx` 안의 함수 이름 = 컴포넌트 단위:
- `HomeScreen` — 페이지 컨테이너
- `TodayGrid` — 6칸 grid 카드
- `ScheduleRow` — 복용 일정 row (체크리스트)

`source/prototype/records.jsx`:
- `RecordsScreen` — 페이지 컨테이너
- `CalendarGrid` + `DateCell` — 월 달력 + 셀
- `LegendDot` — 하단 범례
- `DayRow` — 그 날 일정 row

`source/prototype/shared.jsx`:
- `TopBar` — 상단 알림 종 아이콘 영역
- `PageHeader` — h1 + 서브
- 아이콘들 (BellIcon, CheckIcon 등)
- 더미 데이터 (`INITIAL_TODAY`, `MONTH_DATA`, `generateDay`, `WEEK_LABELS`)

---

## ✅ 구현 체크리스트

1. [ ] `colors_and_type.css` 토큰 → 타겟 코드베이스 토큰 시스템에 매핑
2. [ ] Pretendard / Wanted Sans Variable 폰트 로딩 (또는 시스템 폴백 — Apple SD Gothic Neo / Noto Sans KR)
3. [ ] `tabular-nums` — 숫자 폰트 feature 활성화 확인
4. [ ] 두 화면을 같은 BottomNav 안에 라우트로 (홈 = `/`, 기록 = `/records`)
5. [ ] 홈 — 토글 시 낙관적 업데이트 + 서버 sync (`PATCH /schedule/{id}` taken/takenAt)
6. [ ] 기록 — 월 데이터 fetch (`GET /records?year=…&month=…` → 31일 완료율 배열)
7. [ ] 기록 — 날짜 선택 시 그 날 상세 fetch
8. [ ] 접근성 — checkbox role + aria-checked, 완료/누락이 색만으로 구분되지 않게 텍스트 동반

질문이나 추가 디테일 필요하면 디자이너에게 핑.
