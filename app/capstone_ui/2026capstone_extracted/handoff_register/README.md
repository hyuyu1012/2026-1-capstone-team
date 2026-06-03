# 안심 케어 — 등록 시트 핸드오프

**복용 약 등록 (MedRegisterSheet)** 과 **식사 일정 등록 (MealRegisterSheet)** 두 개의 바텀시트를 본 앱에 옮기는 핸드오프 패키지입니다.

```
handoff_register/
├── README.md
└── source/
    ├── app.jsx           ← 두 시트 + RegisterSheet(분기 메뉴) + 공유 헬퍼
    └── wanted/
        └── colors_and_type.css
```

핵심 컴포넌트는 `source/app.jsx` 안에 다 들어있습니다:
- `RegisterSheet` — FAB 누르면 뜨는 1차 메뉴 (복용 약 / 식사 일정 / 처방전 스캔)
- `MedRegisterSheet` — 복용 약 등록 바텀시트
- `MealRegisterSheet` — 식사 일정 등록 바텀시트
- 공유 헬퍼: `FieldLabel`, `QuickBtn`, `periodOf`, `addMinutes`, 상수 `REGISTERED_MEALS`, `TIMING_OPTIONS`, `MEAL_PRESETS`, `DAY_OPTIONS`

---

## 🎨 공통 비주얼 규칙 (두 시트 동일)

### 시트 컨테이너
- **백드롭**: `position: absolute; inset: 0; background: rgba(23,23,25,0.40);` 페이드인 200ms
- **시트 본체**: 흰 배경, `border-radius: 20px 20px 0 0`, `padding: 8px 0 24px`, slideUp 260ms `cubic-bezier(0.2, 0, 0, 1)`, `max-height: 92%`
- 백드롭 클릭 → 닫기 / 시트 본체는 `stopPropagation`
- **드래그 핸들**: 40×4 라운드 바, `--line-normal-normal`, top center 마진 `6px auto 14px`
- 본체는 세로 flex 컬럼 — 헤더(고정) / 스크롤 영역(`flex: 1; overflow-y: auto`) / CTA(고정, 상단 1px hairline)

### 헤더
- 좌: 시트 제목 — Display 폰트 19px / 700 / `letter-spacing: -0.018em` / `--label-strong`
- 우: "취소" 텍스트 버튼 — 13px / 600 / `--label-neutral`, transparent border-none

### 필드 라벨 (`FieldLabel`)
캡스 스타일: 11.5px / 700 / `letter-spacing: 0.1em` / uppercase / `--label-neutral`. 기본 marginBottom 10. `inline` prop 켜면 0.

### 입력 박스
- padding `12px 14px`, 1px `--line-normal-normal` border, radius **12**, fontSize 14, weight 500
- focus 시 `border-color` → `--primary-normal` (onFocus/onBlur 핸들러로 직접 토글)
- 14px placeholder, `--label-strong` color

### CTA 버튼 (저장)
- 컨테이너: padding `14px 24px 0`, marginTop 14, 상단 1px `--line-normal-neutral`
- 버튼: 가로 100%, 세로 padding 14px, radius **12**, fontSize 15, weight 700
- 활성: `--primary-normal` 배경, 흰 글씨, `box-shadow: 0 6px 14px rgba(0,102,255,0.24)`
- 비활성: `--fill-alternative` 배경, `--label-alternative` 글씨

### 체크박스 패턴
- 22×22, **radius 6** (홈/기록의 동그라미와 구분하기 위해 라운드 사각형)
- 활성: `--primary-normal` 채움 + 흰 ✓ (stroke 3, width 12)
- 비활성: transparent + 1.5px `--line-normal-normal` border

### 카드형 체크 옵션 (식사 목록·권한 등에 쓰는 큰 박스)
- 가로 100%, padding `12~14px 14px`, gap 12, radius 12
- 활성: 1px `--primary-normal` border + `rgba(0,102,255,0.04)` 배경
- 비활성: 1px `--line-normal-normal` border + 흰 배경
- transition 150ms

---

## 1. 식사 일정 등록 — `MealRegisterSheet`

### 진입 경로
FAB(+) → 1차 시트 "새로 등록하기" → **식사 일정 등록** 항목 클릭 → 본 시트 열림.

### 필드 4개

#### 1-1. 식사 이름 (`name`)
- 텍스트 input, placeholder `"예: 아침"`
- 아래 **프리셋 칩** (`MEAL_PRESETS`): 아침 · 점심 · 저녁
  - 알약 버튼, padding `6px 12px`, 흰 배경, 1px `--line-normal-normal` border
  - 클릭 시: `name` ← 프리셋 이름, `time` ← 프리셋 시간 (08:30 / 12:30 / 18:30) 으로 같이 채움
  - 활성 표시 (현재 name 과 일치): primary blue border + 텍스트 + `rgba(0,102,255,0.06)` 배경

#### 1-2. 시간 (`time`)
- 박스 컨테이너: 1px border, radius 12, padding `12px 14px`, flex row
- 내부에 native `<input type="time">` — Display 폰트 18px / 700 / tabular-nums
- 우측에 자동 시간대 라벨 11.5px / 700 / caps — `periodOf(time)` 으로 계산 (아침/점심/오후/저녁/밤)

#### 1-3. 요일 (`days: Set<DayId>`)
- 헤더: 좌측 "요일" 라벨 / 우측 "매일" "평일" `QuickBtn` 두 개
  - `QuickBtn` — 11px / 700 알약, primary border + 텍스트 + `rgba(0,102,255,0.08)` 배경 (활성)
- 7칸 grid: `gridTemplateColumns: repeat(7, 1fr)`, gap 6
  - 각 셀 aspect 1:1, radius 10, fontSize 13 / 700
  - 활성: `--primary-normal` 채움 + 흰 글씨 + `box-shadow: 0 2px 6px rgba(0,102,255,0.22)`
  - 비활성: `--fill-alternative` 배경, 색은 일요일 `--status-cautionary` / 평일 `--label-neutral`
- 기본값: 7일 모두 선택

#### 1-4. 권한 — 보호자 미루기 (`guardianCanDefer`)
- 큰 체크 박스 카드 (위 "카드형 체크 옵션" 스타일)
- 좌측 22×22 체크박스 (사각 radius 6) + 우측 텍스트 영역
- 제목: "보호자가 일정을 미룰 수 있게 할까요?" — 13.5px / 600
- 서브: "식사 시간을 30분~2시간 미룰 수 있어요." — 11.5px / 500 / `--label-neutral`
- 기본값: `true`

### 저장 가드 (`canSave`)
- 이름 trim 길이 > 0
- 요일 set size > 0

### 데이터 형태 (저장 시 보낼 페이로드)
```ts
type MealSchedule = {
  name: string;
  time: string;            // "HH:mm"
  days: ('mon'|'tue'|'wed'|'thu'|'fri'|'sat'|'sun')[];
  guardianCanDefer: boolean;
};
```

---

## 2. 복용 약 등록 — `MedRegisterSheet`

식사 등록과 같은 시트 컨테이너를 쓰지만 **핵심 차이**: 약 시간은 직접 입력할 수 없고 **등록된 식사를 기준으로 식전/식후 시점만 설정**할 수 있습니다.

### 진입 경로
FAB(+) → 1차 시트 → **복용 약 등록** 클릭.

### 필드 5개

#### 2-1. 약 이름 (`name`)
- 텍스트 input, placeholder `"예: 암로디핀"`

#### 2-2. 용량 (`dose`)
- 텍스트 input, placeholder `"예: 5mg 1정"`

#### 2-3. 복용 식사 (`meals: Set<MealId>`)
- 헤더 라벨 "복용 식사"
- 등록된 식사 목록을 카드형 체크박스로 **다중 선택**
- 각 row:
  - 좌: 22×22 체크박스
  - 가운데: 식사 이름 14px / 600 / `--label-strong`
  - 우: 식사 시간 12.5px / 500 / `--label-alternative` / tabular-nums
- 도움말 (목록 아래): "등록된 식사 일정에 맞춰 복용 알림을 보냅니다." — 11px / 500 / `--label-alternative`
- 본 프로토타입에선 `REGISTERED_MEALS` 상수가 더미 데이터:
  ```js
  [
    { id: 'breakfast', name: '아침', time: '08:30' },
    { id: 'lunch',     name: '점심', time: '12:30' },
    { id: 'dinner',    name: '저녁', time: '18:30' },
  ]
  ```
- **실제 구현 시**: 환자의 등록된 식사 일정을 fetch 해서 채워야 함. 식사 등록이 0개면 빈 상태 UI 필요(예: "먼저 식사 일정을 등록해주세요" + 식사 등록 시트로 이동 CTA).

#### 2-4. 복용 시점 (`timings: Set<TimingId>`)
- 헤더 라벨 "복용 시점"
- 두 옵션을 **다중 선택 체크박스**로 (식전/식후 둘 다 켤 수 있음)
- 가로 flex 1:1 두 칸, gap 8, 카드형 체크 옵션 스타일
- 각 row: 좌 20×20 체크박스 + "식전 30분" / "식후 30분" 텍스트 (13.5 / 600~700)
- `TIMING_OPTIONS` 상수:
  ```js
  [
    { id: 'before', label: '식전', offsetMin: -30 },
    { id: 'after',  label: '식후', offsetMin: 30 },
  ]
  ```
- 기본값: `{ after }`

#### 2-5. 알림 시각 미리보기 (조건부)
- `meals.size > 0 && timings.size > 0` 일 때만 표시
- 박스: padding `14px 16px`, `rgba(0,102,255,0.04)` 배경, 1px `rgba(0,102,255,0.18)` border, radius 12
- 헤더 캡스 "알림 시각" — 11px / 700 / `--primary-normal`
- 각 라인:
  - 좌: "아침 식후 30분" (13px / 500 / `--label-strong`)
  - 우: 계산된 시각 "09:00" (13px / 700 / `--primary-normal` / tabular-nums)
- 시간 계산: `addMinutes(meal.time, timing.offsetMin)` — 24h wrap-around 처리됨
- **시간 순으로 정렬해서 표시** (sort by time ASC)
- 식사 × 시점 곱하기 만큼의 라인이 나옴 (3 식사 × 2 시점 = 최대 6줄)

#### 2-6. 권한 — 보호자 미루기 (`guardianCanDefer`)
- 식사 시트와 동일한 카드형 체크박스
- 서브 카피만 다름: "복용 시각을 30분~2시간 미룰 수 있어요."
- 기본값: `true`

### 저장 가드 (`canSave`)
- 이름 trim 길이 > 0
- 식사 set size > 0
- 시점 set size > 0

### 데이터 형태
```ts
type MedSchedule = {
  name: string;
  dose: string;                          // optional 가능
  mealRefs: MealId[];                    // 어떤 식사를 따라가는지
  timings: ('before' | 'after')[];       // 다중
  offsetMin: number;                     // 현재 ±30 고정 — 향후 확장 시 timing 별로 분리
  guardianCanDefer: boolean;
};
// 알림 시각은 server-side 또는 client-side에서
// meals × timings 조합으로 계산: addMinutes(meal.time, offsetMin)
```

### 디자인 의도 — 왜 시간을 직접 입력 안 하나
어르신의 약 복용은 보통 식사 전후 30분/1시간이 기준이기 때문에, 시간을 자유롭게 잡게 하면 "식사 시간과 어긋난 시각에 알림이 오는" 실수가 잦습니다. 식사 일정을 단일 진실 소스로 두고 약 시각이 그것을 따라가도록 묶어두면, 식사 시간이 바뀔 때 약 알림도 자동으로 따라갑니다 — 환자 가족의 일정 관리 부담을 줄이는 핵심 결정.

---

## ⚙️ 인터랙션 상세

| 동작 | 효과 |
|---|---|
| 백드롭 탭 | 시트 닫힘 |
| 취소 버튼 | 시트 닫힘 (입력값 폐기) |
| 저장 버튼 (활성) | onSave 후 시트 닫힘 |
| 식사/요일/시점 토글 | 즉시 set 업데이트, 활성 표시 150ms |
| 식사 프리셋 클릭 | name + time 동시 업데이트 |
| 약 시트 식사 선택 | 미리보기 박스 즉시 추가 |
| 약 시트 시점 토글 | 미리보기 라인 즉시 추가/제거, 시간순 재정렬 |

### 키보드/접근성 (구현 시)
- 시트 열 때 첫 입력 필드 autoFocus
- ESC 키 → 시트 닫힘
- 체크박스에 `role="checkbox"` + `aria-checked`
- 다중 선택 그룹에 `role="group"` + 라벨 연결

---

## 🧱 의존성

- 두 시트 모두 `RegisterOption` (1차 시트의 큰 옵션 카드) 와 `RegisterSheet` (1차 시트 자체) 를 거쳐서 진입합니다. 그것도 `app.jsx` 에 포함되어 있음.
- 1차 시트의 옵션:
  1. **복용 약 등록** → onMed 콜백
  2. **식사 일정 등록** → onMeal 콜백
  3. **처방전 스캔** → 더미 (badge "새 기능")
- App 컴포넌트에서 `mealOpen`, `medOpen` 두 boolean state 로 어떤 시트를 띄울지 결정.

```jsx
{fabOpen && <RegisterSheet
  onClose={() => setFabOpen(false)}
  onMeal={() => { setFabOpen(false); setMealOpen(true); }}
  onMed={() => { setFabOpen(false); setMedOpen(true); }}
/>}
{mealOpen && <MealRegisterSheet onClose={() => setMealOpen(false)} />}
{medOpen  && <MedRegisterSheet  onClose={() => setMedOpen(false)} />}
```

---

## ✅ 체크리스트

1. [ ] `colors_and_type.css` 토큰 매핑
2. [ ] 시트 컴포넌트 — 디자인 시스템에 BottomSheet 이 있으면 그걸로, 없으면 위 명세대로
3. [ ] 두 시트 공통 헤더/CTA 패턴은 별도 컴포넌트로 추출 권장
4. [ ] 식사 시트 — 요일 multi-select, 매일/평일 단축
5. [ ] 약 시트 — 등록된 식사 fetch (`GET /meals/{patientId}`), 0개일 때 빈 상태 처리
6. [ ] 약 시트 — 알림 시각 미리보기 (식사 × 시점 조합 계산)
7. [ ] 보호자 권한 — 저장 시 schedule 에 `guardianCanDefer` 필드 포함
8. [ ] 알림 백엔드 — `guardianCanDefer === true` 이면 보호자 앱에도 미루기 액션 푸시
9. [ ] 접근성 — checkbox role/aria, ESC/포커스 트랩

질문 있으면 디자이너에게 핑.
