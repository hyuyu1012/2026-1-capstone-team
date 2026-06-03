// ─── Shared data, BottomNav, icons ───────────────────────────────
const PATIENT = { name: '이순자', relation: '어머니', age: 78, profileInitial: '이' };
const TODAY = 27;
const MONTH_LABEL = '2026년 5월';
const FIRST_OFFSET = 5; // 5월 1일 = 금요일 (일=0)
const DAYS_IN_MONTH = 31;

// 31일 완료율 — 0~1, 미래는 null
const MONTH_DATA = [
  1.0, 0.83, 1.0, 1.0, 0.67,  1.0, 1.0,
  0.83, 1.0, 1.0, 0.50, 1.0,  1.0, 1.0,
  1.0, 0.67, 1.0, 1.0, 0.83,  0.33, 1.0,
  1.0, 1.0, 1.0, 1.0, 0.83,   0.50, null,
  null, null, null,
];

// 오늘 일정 (med = 복용, meal = 식사)
const INITIAL_TODAY = [
  { id: '1', kind: 'med',  name: '암로디핀 5mg',         dose: '1정', time: '08:00', taken: true,  takenAt: '08:12' },
  { id: '2', kind: 'meal', name: '아침 식사',                          time: '08:30', taken: true,  takenAt: '08:38' },
  { id: '3', kind: 'med',  name: '메트포르민 500mg',      dose: '1정', time: '12:30', taken: true,  takenAt: '12:41' },
  { id: '4', kind: 'meal', name: '점심 식사',                          time: '12:30', taken: false },
  { id: '5', kind: 'meal', name: '저녁 식사',                          time: '18:30', taken: false },
  { id: '6', kind: 'med',  name: '아토르바스타틴 10mg',   dose: '1정', time: '20:00', taken: false },
];

const DAY_TEMPLATE = [
  { kind: 'med',  name: '암로디핀 5mg',         dose: '1정', time: '08:00' },
  { kind: 'meal', name: '아침 식사',                          time: '08:30' },
  { kind: 'med',  name: '메트포르민 500mg',      dose: '1정', time: '12:30' },
  { kind: 'meal', name: '점심 식사',                          time: '12:30' },
  { kind: 'meal', name: '저녁 식사',                          time: '18:30' },
  { kind: 'med',  name: '아토르바스타틴 10mg',   dose: '1정', time: '20:00' },
];

// 등록된 약 목록 (Settings에서 관리)
const MEDS = [
  { id: 'm1', name: '암로디핀', dose: '5mg', count: '1정', schedule: '매일 08:00', purpose: '혈압', completion: 0.96 },
  { id: 'm2', name: '메트포르민', dose: '500mg', count: '1정', schedule: '매일 12:30', purpose: '당뇨', completion: 0.93 },
  { id: 'm3', name: '아토르바스타틴', dose: '10mg', count: '1정', schedule: '매일 20:00', purpose: '콜레스테롤', completion: 0.78 },
];

const WEEK_LABELS = ['일','월','화','수','목','금','토'];

function generateDay(date) {
  const pct = MONTH_DATA[date - 1];
  if (pct === null || pct === undefined) {
    return DAY_TEMPLATE.map(t => ({ ...t, taken: false }));
  }
  const totalToTake = Math.round(pct * DAY_TEMPLATE.length);
  const order = [3, 4, 5, 0, 2, 1];
  const missedSet = new Set(order.slice(0, DAY_TEMPLATE.length - totalToTake));
  return DAY_TEMPLATE.map((t, i) => {
    if (missedSet.has(i)) return { ...t, taken: false };
    const [h, m] = t.time.split(':').map(Number);
    const drift = ((date * 7 + i * 13) % 17) - 4;
    const total = h * 60 + m + drift;
    const hh = Math.floor(total / 60), mm = total % 60;
    const takenAt = `${String(hh).padStart(2,'0')}:${String(mm).padStart(2,'0')}`;
    return { ...t, taken: true, takenAt };
  });
}

// ─── Icons ────────────────────────────────────────────────────────
const NavIcon = ({ children, size = 22, stroke = 1.6, color = 'currentColor' }) => (
  <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke={color}
    strokeWidth={stroke} strokeLinecap="round" strokeLinejoin="round">{children}</svg>
);
const NavIconHome     = (p) => <NavIcon {...p}><path d="M3.5 11 12 4l8.5 7"/><path d="M5.5 10v9.5h13V10"/></NavIcon>;
const NavIconRecords  = (p) => <NavIcon {...p}><rect x="4" y="5" width="16" height="15" rx="2"/><path d="M8 3v4M16 3v4M4 10h16"/></NavIcon>;
const NavIconAdd      = (p) => <NavIcon {...p}><path d="M12 5v14M5 12h14"/></NavIcon>;
const NavIconStats    = (p) => <NavIcon {...p}><path d="M4 20h16"/><rect x="6" y="11" width="3" height="7" rx="0.5"/><rect x="11" y="7" width="3" height="11" rx="0.5"/><rect x="16" y="13" width="3" height="5" rx="0.5"/></NavIcon>;
const NavIconSettings = (p) => <NavIcon {...p}><circle cx="12" cy="12" r="3"/><path d="M19.4 15a1.7 1.7 0 0 0 .34 1.86l.06.06a2 2 0 1 1-2.83 2.83l-.06-.06a1.7 1.7 0 0 0-1.86-.34 1.7 1.7 0 0 0-1.03 1.56V21a2 2 0 1 1-4 0v-.08A1.7 1.7 0 0 0 9 19.4a1.7 1.7 0 0 0-1.86.34l-.06.06a2 2 0 1 1-2.83-2.83l.06-.06A1.7 1.7 0 0 0 4.66 15 1.7 1.7 0 0 0 3.1 14H3a2 2 0 1 1 0-4h.08A1.7 1.7 0 0 0 4.66 9a1.7 1.7 0 0 0-.34-1.86l-.06-.06a2 2 0 1 1 2.83-2.83l.06.06A1.7 1.7 0 0 0 9 4.66 1.7 1.7 0 0 0 10 3.1V3a2 2 0 1 1 4 0v.08A1.7 1.7 0 0 0 15 4.66a1.7 1.7 0 0 0 1.86-.34l.06.06a2 2 0 1 1 2.83 2.83l-.06.06A1.7 1.7 0 0 0 19.34 9c.16.4.46.72.84.93"/></NavIcon>;

const BellIcon = ({ size=20, stroke=1.6 }) => (
  <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke="currentColor"
    strokeWidth={stroke} strokeLinecap="round" strokeLinejoin="round">
    <path d="M6 18V11a6 6 0 1 1 12 0v7"/>
    <path d="M3.5 18h17"/>
    <path d="M10 21a2 2 0 0 0 4 0"/>
  </svg>
);
const ChevronRight = ({ size=18 }) => (
  <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke="currentColor"
    strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
    <path d="M9 6l6 6-6 6"/>
  </svg>
);
const ChevronLeft = ({ size=16 }) => (
  <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke="currentColor"
    strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
    <path d="M15 6l-6 6 6 6"/>
  </svg>
);
const CheckIcon = ({ size=14, color='#fff' }) => (
  <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke={color}
    strokeWidth="2.6" strokeLinecap="round" strokeLinejoin="round">
    <path d="M5 12.5l4.5 4.5L20 7"/>
  </svg>
);

// ─── BottomNav (shared) ───────────────────────────────────────────
function BottomNav({ active, onChange, onFab }) {
  const items = [
    { id: 'home',     label: '홈',   icon: NavIconHome },
    { id: 'records',  label: '기록', icon: NavIconRecords },
    { id: 'register', label: '등록', icon: NavIconAdd, isFab: true },
    { id: 'stats',    label: '통계', icon: NavIconStats },
    { id: 'settings', label: '설정', icon: NavIconSettings },
  ];
  const accent = 'var(--primary-normal)';
  return (
    <div style={{ position: 'relative', height: 84, flexShrink: 0 }}>
      <svg viewBox="0 0 360 84" preserveAspectRatio="none"
        style={{ position: 'absolute', inset: 0, width: '100%', height: '100%', display: 'block' }}>
        <defs>
          <filter id="navshadow-proto" x="-10%" y="-50%" width="120%" height="200%">
            <feDropShadow dx="0" dy="-2" stdDeviation="6" floodColor="#000" floodOpacity="0.05"/>
          </filter>
        </defs>
        <path filter="url(#navshadow-proto)"
          d="M0 12 L140 12 C148 12 152 16 154 22 C158 38 168 48 180 48 C192 48 202 38 206 22 C208 16 212 12 220 12 L360 12 L360 84 L0 84 Z"
          fill="#fff" stroke="rgba(112,115,124,0.14)" strokeWidth="1"/>
      </svg>
      <div style={{
        position: 'absolute', inset: 0, display: 'grid',
        gridTemplateColumns: '1fr 1fr 1fr 1fr 1fr', paddingTop: 18,
      }}>
        {items.map((it) => {
          const isActive = active === it.id;
          if (it.isFab) {
            return (
              <button key={it.id} onClick={onFab} style={{
                background: 'transparent', border: 'none', padding: 0, cursor: 'pointer',
                position: 'relative', display: 'flex', flexDirection: 'column',
                alignItems: 'center', fontFamily: 'inherit',
              }}>
                <div style={{
                  position: 'absolute', top: -22,
                  width: 52, height: 52, borderRadius: 999,
                  background: accent, color: '#fff',
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                  boxShadow: '0 6px 16px rgba(0,102,255,0.28)',
                }}>
                  <NavIconAdd size={24} stroke={2.2} color="#fff" />
                </div>
                <div style={{
                  marginTop: 36, fontSize: 10.5, fontWeight: 600,
                  color: 'var(--label-alternative)', letterSpacing: '0.04em',
                }}>등록</div>
              </button>
            );
          }
          return (
            <button key={it.id} onClick={() => onChange(it.id)} style={{
              background: 'transparent', border: 'none', padding: 0, cursor: 'pointer',
              display: 'flex', flexDirection: 'column', alignItems: 'center',
              color: isActive ? accent : 'var(--label-alternative)', gap: 4,
              fontFamily: 'inherit',
            }}>
              <it.icon size={22} stroke={isActive ? 2 : 1.6} color="currentColor" />
              <span style={{
                fontSize: 10.5, fontWeight: isActive ? 700 : 500, letterSpacing: '0.02em',
              }}>{it.label}</span>
            </button>
          );
        })}
      </div>
    </div>
  );
}

// ─── Top bar ──────────────────────────────────────────────────────
function TopBar({ onBell }) {
  return (
    <div style={{
      padding: '12px 20px 0', display: 'flex', alignItems: 'center', gap: 8,
      flexShrink: 0,
    }}>
      <div style={{ flex: 1 }} />
      <button aria-label="알림" onClick={onBell} style={{
        width: 36, height: 36, borderRadius: 999, border: 'none',
        background: 'transparent', cursor: 'pointer',
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        color: 'var(--label-strong)', padding: 0, position: 'relative',
      }}>
        <BellIcon />
        <div style={{
          position: 'absolute', top: 8, right: 9, width: 7, height: 7,
          borderRadius: 999, background: 'var(--status-cautionary)',
          border: '1.5px solid #F4F5F7',
        }}/>
      </button>
    </div>
  );
}

// ─── Page Header (h1 + subtitle) ──────────────────────────────────
function PageHeader({ title, subtitle }) {
  return (
    <div style={{ padding: '8px 0 0' }}>
      <h1 style={{
        margin: 0,
        fontFamily: 'var(--font-display)',
        fontSize: 28, fontWeight: 700,
        letterSpacing: '-0.028em', lineHeight: 1.15,
        color: 'var(--label-strong)',
      }}>{title}</h1>
      {subtitle && (
        <p style={{
          margin: '6px 0 0',
          fontSize: 13.5, fontWeight: 500,
          color: 'var(--label-neutral)',
          letterSpacing: '-0.002em',
        }}>{subtitle}</p>
      )}
    </div>
  );
}

// ─── Section header (small uppercase) ─────────────────────────────
function SectionHeader({ children, right }) {
  return (
    <div style={{
      display: 'flex', alignItems: 'baseline', justifyContent: 'space-between',
      marginBottom: 10, padding: '0 4px',
    }}>
      <span style={{
        fontSize: 11.5, fontWeight: 700, letterSpacing: '0.1em',
        color: 'var(--label-neutral)', textTransform: 'uppercase',
      }}>{children}</span>
      {right && (
        <span style={{
          fontSize: 11.5, fontWeight: 700, letterSpacing: '0.02em',
          color: 'var(--label-alternative)', fontVariantNumeric: 'tabular-nums',
        }}>{right}</span>
      )}
    </div>
  );
}

// Expose globally for sibling Babel scripts
Object.assign(window, {
  PATIENT, TODAY, MONTH_LABEL, FIRST_OFFSET, DAYS_IN_MONTH,
  MONTH_DATA, INITIAL_TODAY, DAY_TEMPLATE, MEDS, WEEK_LABELS,
  generateDay,
  NavIcon, NavIconHome, NavIconRecords, NavIconAdd, NavIconStats, NavIconSettings,
  BellIcon, ChevronRight, ChevronLeft, CheckIcon,
  BottomNav, TopBar, PageHeader, SectionHeader,
});
