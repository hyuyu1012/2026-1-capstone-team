# 안심 케어 (Ansim Care) — 디자인 핸드오프

부모님의 약 복용·식사를 보호자가 함께 챙기는 모바일 앱. 보호자 관점의 안드로이드 앱 (360×800 기준) 디자인 묶음입니다.

---

## 📁 About the Design Files

이 폴더 안의 파일들은 **HTML로 만든 디자인 레퍼런스 (prototype)** 이고, 그대로 가져다 쓰는 production code 가 아닙니다. 개발 작업은:

> **이 HTML 디자인을 타겟 코드베이스(React Native / Flutter / Swift / Kotlin / Web 등)의 기존 컴포넌트 라이브러리·패턴으로 다시 구현**

하는 것입니다. 코드베이스가 아직 없다면 적합한 프레임워크를 선택해서 구현해 주세요. HTML 파일은 색·간격·동작·카피의 진실 소스(source of truth)일 뿐, 직접 임베드/이식하지 않습니다.

---

## 🎯 Fidelity — **High-fidelity (hifi)**

- 색·타이포·간격·radius는 디자인 시스템 토큰 기준의 **확정값**입니다 (`screens/wanted/colors_and_type.css`)
- 카피는 한국어로 확정. 화면별 마이크로카피도 그대로 사용해 주세요
- 인터랙션·상태 변화는 prototype에서 작동하는 그대로 (탭, 토글, 시트, 라우팅)
- 아이콘은 inline SVG 로 그려져 있어서 그대로 추출 가능 (또는 라이브러리 등가물로 대체)

---

## 🗂 Screens

### 1. Login (`screens/Login.html`, `screenshots/1-Login.png`)
**Purpose** 앱 첫 진입. 소셜 로그인으로 가볍게 시작.

**Layout** 세로 중앙정렬. 위에서 아래로:
1. 앱 아이콘 (56×56, 라운드 16, primary 블루 배경, 흰 shield 아이콘)
2. 앱 이름 "안심 케어" (h3 — 22px / weight 700 / 진한 색)
3. 부제 "부모님의 하루를 함께 챙깁니다." (14px / label-neutral)
4. 소셜 버튼 3개 (full-width, gap 10px):
   - **카카오로 시작하기** — 배경 `#FEE500`, 검정 텍스트, 좌측 말풍선 아이콘
   - **Google로 시작하기** — 흰 배경, 1px border, "G" 컬러 로고
   - **Apple로 시작하기** — 검정 배경, 흰 텍스트, 좌측 사과 아이콘
5. 하단 약관 텍스트 — 11.5px, "이용약관"/"개인정보 처리방침" 만 강조

**Components** 모두 radius 12, 높이 48, padding `12px 16px`.

---

### 2. NewPatient (`screens/NewPatient.html`, `screenshots/2-NewPatient.png`)
**Purpose** 첫 로그인 직후 보호자가 마주하는 분기 화면 — "기존 환자 연결" vs "새 환자 등록" 의 2가지 UX 안 (A/B)을 한 화면에 나란히 보여주는 디자인 비교 모드.

**구성** A·B 두 안드로이드 디바이스 프레임이 좌우로 나란히. 윗부분에 한국어 설명 + 버전 라벨 칩(• 버전 A · 카드 선택 / • 버전 B · 코드 우선).

**Version A — 카드 선택형**
- "기존 환자 연결" (primary blue 배경 선택 상태), "새 환자 등록" (white 배경) 카드 2장
- 각 카드에 아이콘 + 제목 + 1줄 설명 + 메타("가장 흔한 경우" / "약 2분 소요")

**Version B — 코드 우선형**
- 페이지 상단에 곧바로 6자리 OTP 입력 박스 (6칸 grid)
- "환자와 연결" CTA → 또는 구분선 → "새 환자 등록" 으로 fallback

**실제 구현 시** 둘 중 한 안만 선택하면 됩니다. PM/디자인이 정하는 안에 따라 카드 화면 또는 OTP-first 화면을 단일 라우트로.

---

### 3. PatientSetup (`screens/PatientSetup.html`, `screenshots/3-PatientSetup.png`)
**Purpose** "새 환자 등록"을 선택한 후 환자(부모님) 기본 정보를 받는 3-step 마법사.

**Layout** Step indicator (1/3, 2/3, 3/3) → 큰 질문 헤더 → 입력 영역 → 하단 sticky CTA. NewPatient와 마찬가지로 디자인 비교 디바이스 프레임으로 표현되어 있을 수 있습니다.

**Step 1** 이름·관계(어머니/아버지/배우자/기타)·생년월일
**Step 2** 복용 중인 약 (자동완성 검색, 처방전 사진 업로드, 직접 입력 — 다음에 약 일정도)
**Step 3** 식사 시간 (아침/점심/저녁 time picker)

각 step 의 하단 CTA = full-width primary 버튼 ("다음" / "완료"). 좌상단 ← 이전, 우상단 진행 인디케이터(1/3).

---

### 4. Prototype v2 — 통합 본앱 (`screens/Prototype v2.html`)
4-탭 안드로이드 앱. 하단 5-슬롯 nav: **홈 · 기록 · [등록 FAB] · 통계 · 설정**.

> Prototype은 모듈화되어 있습니다 — `screens/prototype/*.jsx` 파일들이 각 화면, `screens/android-frame.jsx`가 디바이스 프레임을 제공.

#### 4-1. 홈 (`screenshots/4-Prototype-Home.png`, `screens/prototype/home.jsx`)
**Purpose** 오늘 약·식사 진행 상태를 한 화면에서 확인.

**구성 (top-to-bottom)**
1. **헤더** — h1 "오늘 현황을 확인하세요" (28px), 서브 "어머니 · 이순자"
2. **한눈에 보기 카드** — 24시 링
   - 카드 padding `20px 18px 16px`, radius 16, 1px border
   - 220×220 SVG 링: 큰 원(radius 88, stroke 8, fill-alternative track) + progress arc(0시→현재시각, primary @ 0.20 opacity)
   - 3·6·9·12·15·18·21시 위치에 짧은 tick (line-normal-normal, 5px)
   - 약 마커 3개: 완료된 약은 primary blue 채워진 원(r=12) + 흰 알약 아이콘, 미복용은 흰 원 + 회색/주황 외곽선 (overdue 면 status-cautionary)
   - 가운데 "지금" 라벨(10px caps) + 큰 시각 "16:30" (display 26px, 700)
   - 외곽: 0시(위) · 6시(우) · 12시(아래) · 18시(좌) 라벨, 각 라벨은 사분면별 transform 으로 정렬
3. **오늘 일정 카드** — 6칸 grid (med/meal 토글 가능)
   - 정사각 셀(aspect-ratio 1:1, radius 8)
   - 완료: primary blue 채움 + 흰 아이콘 + 작은 그림자
   - 미완료: 흰 배경 + 1.5px label-alternative 외곽선 + 회색 아이콘
   - 약/식사 아이콘 (inline SVG)
4. **복용 일정 리스트** — 항목 6개
   - 카드 안에서 row 형식, padding `12px 18px`, 첫 row 외 위쪽 1px border
   - 완료 row 는 `rgba(0,102,255,0.04)` 배경, 약 이름 색 primary blue
   - 우측에 완료 시각 (예 "08:12 완료") / 대기 상태는 회색 "대기"

#### 4-2. 기록 (`screenshots/5-Prototype-Records.png`, `screens/prototype/records.jsx`)
**Purpose** 월 달력 + 선택한 날의 상세 복용 기록.

**구성**
1. 헤더 "복용 기록을 확인하세요"
2. **달력 카드**
   - 헤더: ← 이전달 / "2026년 5월" (14px / 700) / 다음달 →
   - 요일 헤더 (일은 cautionary 주황, 평일은 alternative)
   - 7×6 grid, 각 셀 aspect 1:1, radius 8
   - 완료율로 채움: 0~0.34 = blue@18%, 0.35~0.67 = blue@40%, 0.68~0.99 = blue@68%, 1.0 = primary full
   - 오늘 = 1.5px label-strong border, 선택일 = 2px 두꺼운 border
   - 미래 날짜 disabled
   - 하단 범례: 적음 ─ □□□□ ─ 많음
3. **선택일 상세** — "5월 27일 수요일" (14px / 700 / label-strong) + 오늘이면 옆에 파란 "오늘" 라벨, 우측 "5 / 6" 카운트 (같은 14px/700/label-alternative)
4. **시간순 약·식사 row 리스트** (홈 일정 row 와 같은 스타일, 단 누락은 cautionary 색으로 "누락" 표시)

#### 4-3. 통계 (`screenshots/6-Prototype-Stats.png`, `screens/prototype/stats.jsx`)
**Purpose** 주·월 단위 복용률과 자주 누락한 항목.

**구성** (색은 primary blue + label 한 톤만 — 카테고리 컬러 없음)
1. 헤더 "복용 패턴을 살펴보세요"
2. **이번 주 카드** — 7일 막대그래프
   - 우상단 "주평균 {n}%" (14px / 700)
   - bar 130px high, width 18px, radius 4
   - 미완료일은 blue@32%, 오늘은 primary full + 위에 라벨 "{n}%"
   - 데이터 없는 미래는 4px high 회색 막대
3. **이번 달 카드** — 면적 차트 (1일~31일)
   - 312×150 SVG, 그라디언트 fill (top 28% → bottom 2%)
   - 2px primary blue 라인
   - 가로 grid: 0%/50%/100% (50%/100%는 dashed 3 3)
   - 오늘 마커: 흰 원(r=5) + label-strong 2px stroke + 아래 점선
   - x축 라벨: 1, 8, 15, 22, 27(오늘 — 700), 31일
   - y축 우측: 0% / 50% / 100% (9px alternative)
4. **자주 누락한 항목** 리스트
   - 카드 row 4개, 약/식사 이름 + 시간 + 우측 빨간 카운트 "6 / 27일"
   - 막대: 4px high, `var(--c-red-60)` (#FF6363) 채움, 가장 많이 누락한 항목 기준 비례

#### 4-4. 설정 (`screenshots/7-Prototype-Settings.png`, `screens/prototype/settings.jsx`)
**Purpose** 환자 프로필·알림·복용 정보·보호자·화면·일반 관리.

**구성** 카드형 섹션 그룹들 (각 섹션 위에 작은 caps 라벨)
1. **환자 프로필 카드** — 56×56 그라디언트 원 아바타("이"), 이름·관계·나이, 우측 "편집" 알약 버튼
2. **알림** — Toggle row 4개 (복용 알림 / 누락 알림 / 보호자에게 푸시 / 알림음)
3. **복용 정보** — Nav row 3개 (복용 일정 관리 [3개 ›] / 식사 시간 설정 [08:30·12:30·18:30 ›] / 처방 기록)
4. **가족 · 보호자** — 보호자 row 2명 (아바타+이름+관계+활성 칩) + "+ 보호자 초대" (primary blue)
5. **화면** — 다크 모드 Toggle + 글자 크기 (가/가/가/가 4-segment, 선택은 primary blue)
6. **일반** — Nav row 3개 (개인정보 / 도움말 / 앱 정보 v1.0.0)
7. 최하단 빨간 "로그아웃" 카드 버튼

**Toggle 컴포넌트** — 44×26 알약, 22×22 흰 thumb, primary blue 활성 / fill-normal 비활성, 180ms transition

---

## 🎨 Design Tokens

전체 토큰: `screens/wanted/colors_and_type.css`. 자주 쓰는 것들 발췌:

### Colors
| Token | Hex / RGBA | 용도 |
|---|---|---|
| `--primary-normal` | `#0066FF` | 주 강조, 완료/활성 상태 |
| `--label-strong` | `rgba(23,23,25,1)` | h1·강조 본문 |
| `--label-normal` | `rgba(46,47,51,0.88)` | 본문 1 |
| `--label-neutral` | `rgba(55,56,60,0.61)` | 본문 2 (서브) |
| `--label-alternative` | `rgba(55,56,60,0.28)` | 캡션 |
| `--line-normal-neutral` | `rgba(112,115,124,0.16)` | 카드 외곽선 |
| `--line-normal-normal` | `rgba(112,115,124,0.22)` | 버튼/입력 외곽선 |
| `--fill-alternative` | `rgba(112,115,124,0.05)` | placeholder 트랙 |
| `--status-cautionary` | `#FF5E00` | 누락·오버듀 강조 (주황) |
| `--c-red-60` | `#FF6363` | 통계 "누락 항목" 라인 (연한 빨강) |
| `--c-green-40` | `#009632` | 보호자 "활성" 칩 |
| Page bg | `#F4F5F7` | 본문 배경 |
| 카카오 노랑 | `#FEE500` | Login 카카오 버튼 |

### Typography
- `--font-sans` Pretendard → Apple SD Gothic Neo → Noto Sans KR
- `--font-display` Wanted Sans Variable (h1, 큰 숫자)
- 본문 페이지 헤더 h1: 28px / weight 700 / `-0.028em`
- 섹션 라벨 (caps): 11.5px / 700 / `letter-spacing: 0.1em` / `text-transform: uppercase` / label-neutral
- 카드 본문 row 제목: 13.5px / 600 / `-0.005em` / label-strong
- 카드 row 서브: 11~11.5px / 500 / label-neutral
- 카운트·시각 등 숫자: `font-variant-numeric: tabular-nums` 권장

### Spacing & Radius
- 모바일 페이지 좌우 padding: 24px
- 카드 padding: `20px 18px` (큰 콘텐츠 카드), `12~14px 18px` (리스트 row)
- 카드 radius: **16** (대부분), **14** (리스트 컨테이너), **12** (작은 칩/입력), **8** (셀), **999** (알약 버튼·뱃지)
- 카드 간 세로 gap: 20px, 섹션 간 gap: 24~28px

### Shadows
- 카드: border 만, 그림자 없음 (가벼운 표현)
- FAB: `0 6px 16px rgba(0,102,255,0.28)`
- 완료된 작은 셀: `0 2px 6px rgba(0,102,255,0.18)`

---

## ⚙️ Interactions & Behavior

### 글로벌
- **하단 nav 탭 전환** — 가운데 + 버튼은 FAB(등록 시트), 나머지 4개는 라우트 전환
- **탭 위치 기억** — `localStorage('care-tab-v2')` 로 새로고침 후 복귀 (prod 에선 라우터 history)
- **상단 알림 종 아이콘** — 우상단 36×36 transparent 버튼, 빨간 작은 dot 으로 unread 표시
- **등록 FAB** → 바텀 시트 (`복용 약 등록 / 식사 일정 등록 / 처방전 스캔(NEW)`) 240ms slide-up

### 홈
- **오늘 일정 6칸** 셀 탭 → 완료/취소 토글 (즉시 색 전환, 150ms)
- **복용 일정 row** 탭 → 같은 토글
- 토글 시 상태는 동일 약 인스턴스에 한해 home 내부 state 로만 (실제 구현 시 서버 sync 필요)

### 기록
- **달력 셀** 탭 → 아래 상세 영역이 그 날의 약·식사 시간 리스트로 즉시 교체
- 미래 셀 disabled (`disabled` 상태, pointer-events none)
- ◀ ▶ 이전/다음 달 (현재 UI 만, 데이터는 단일 월)

### 통계
- 현재는 정적. 향후 기간 필터(주/월/3개월) 추가 여지

### 설정
- Toggle/세그먼트 컨트롤 즉시 반영 (애니메이션 180ms `cubic-bezier(0.2, 0, 0, 1)`)
- 글자 크기 4단계 (작게/보통/크게/매우 크게) — 실제 구현 시 root font-size scale 에 연동

### 애니메이션 토큰
```css
--ease-standard: cubic-bezier(0.2, 0, 0, 1);
--ease-emphasized: cubic-bezier(0.2, 0, 0, 1);
```

### 키보드/접근성 (구현 시 보강)
- 모든 인터랙티브 요소는 button/anchor 시맨틱
- 토글에 `role="switch"`, `aria-checked`
- 큰 글씨 모드 대응 (글자 크기 설정 + 시스템 dynamic type)
- 색만으로 상태 구분 X — 텍스트(완료/대기/누락)로도 표시 중

---

## 📦 State Management (참고)

화면별로 필요한 데이터 모델 스케치:

```ts
type ScheduleItem = {
  id: string;
  kind: 'med' | 'meal';
  name: string;
  dose?: string;        // 약 only
  time: string;         // "HH:mm"
  taken: boolean;
  takenAt?: string;     // 완료 시각
};

type MonthDay = number | null;   // 0..1 완료율, null = 미래
type MonthData = MonthDay[];     // 31개

type Med = {
  id: string;
  name: string;
  dose: string;
  count: string;        // "1정"
  schedule: string;     // "매일 08:00"
  purpose: string;      // "혈압"
};

type Guardian = { id; name; relation; active: boolean };
type Patient = { name; relation; age; profileColor };
```

서버에서 가져올 것:
- `todayItems(patientId, date)` → ScheduleItem[]
- `monthData(patientId, year, month)` → MonthData
- `dayDetail(patientId, date)` → ScheduleItem[]
- `meds(patientId)` → Med[]
- `guardians(patientId)` → Guardian[]
- `toggle(itemId, taken)` → mutation

---

## 🧱 Assets

- **아이콘** 모두 inline SVG. 외부 라이브러리 없음 (lucide / heroicons 등 유사 스타일 라이브러리로 1:1 매칭 가능)
- **이미지** 없음. 환자 아바타는 그라디언트 + 이니셜로 임시 표현. 실제 사진 업로드 기능은 별도 설계 필요
- **폰트** Pretendard (sans), Wanted Sans Variable (display) — `screens/wanted/fonts/` 폴더에 webfont 포함

---

## 📂 Files

```
design_handoff_ansim_care/
├── README.md                              ← 이 문서
├── screenshots/                           ← 화면별 PNG (전체 컨텐츠)
│   ├── 1-Login.png
│   ├── 2-NewPatient.png
│   ├── 3-PatientSetup.png
│   ├── 4-Prototype-Home.png
│   ├── 5-Prototype-Records.png
│   ├── 6-Prototype-Stats.png
│   └── 7-Prototype-Settings.png
└── screens/                               ← HTML 디자인 소스
    ├── Login.html
    ├── NewPatient.html
    ├── PatientSetup.html
    ├── Prototype v2.html                  ← 4-탭 통합 본앱
    ├── android-frame.jsx                  ← 디바이스 프레임 컴포넌트
    ├── prototype/
    │   ├── shared.jsx                     ← 공유 데이터·BottomNav·아이콘
    │   ├── home.jsx                       ← 홈 탭 + 24시 링
    │   ├── records.jsx                    ← 기록 탭 + 달력
    │   ├── stats.jsx                      ← 통계 탭
    │   ├── settings.jsx                   ← 설정 탭
    │   └── app.jsx                        ← 라우터 + 등록 시트
    └── wanted/
        ├── colors_and_type.css            ← 디자인 토큰 (color + type)
        └── fonts/                         ← Pretendard / Wanted Sans webfont
```

---

## ✅ 개발 체크리스트 (제안)

1. [ ] 디자인 토큰 → 타겟 코드베이스 토큰으로 매핑 (Theme provider / Style Dictionary)
2. [ ] 한글 폰트 로딩 (Pretendard + Wanted Sans Variable) — 시스템 폴백 포함
3. [ ] 4-탭 라우터 + 하단 nav (FAB 가운데 슬롯)
4. [ ] 24시 링·면적 그래프는 svg 직접 그리거나 d3/victory 등으로 (정확히 같은 비율 유지)
5. [ ] 달력 — 월 단위 데이터 fetch + 셀 색 보간
6. [ ] 토글·세그먼트·시트 — 디자인 시스템 컴포넌트로 매핑하되 motion 시간 유지 (180~240ms)
7. [ ] 약 복용 토글 → 낙관적 업데이트 + 서버 sync
8. [ ] 보호자 푸시 알림 트리거 (누락 30분 후)
9. [ ] 접근성 — VoiceOver/TalkBack 라벨, 큰 글씨 모드, 색 대비

---

질문이 있다면 디자이너에게 핑. 카피 변경·기능 추가는 디자인 단에서 확정 후 진행 권장.
