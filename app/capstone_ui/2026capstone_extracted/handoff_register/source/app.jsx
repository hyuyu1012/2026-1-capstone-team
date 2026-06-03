// ─── App (tab router) ─────────────────────────────────────────────
function App() {
  const [tab, setTab] = React.useState('home');
  const [items, setItems] = React.useState(INITIAL_TODAY);
  const [fabOpen, setFabOpen] = React.useState(false);
  const [mealOpen, setMealOpen] = React.useState(false);
  const [medOpen, setMedOpen] = React.useState(false);
  const scrollRef = React.useRef(null);

  // Persist tab
  React.useEffect(() => {
    const saved = localStorage.getItem('care-tab-v2');
    if (saved) setTab(saved);
  }, []);
  React.useEffect(() => {
    localStorage.setItem('care-tab-v2', tab);
    if (scrollRef.current) scrollRef.current.scrollTop = 0;
  }, [tab]);

  const toggleItem = (id) => setItems(items.map(it =>
    it.id === id
      ? { ...it, taken: !it.taken, takenAt: !it.taken ? '16:32' : undefined }
      : it
  ));

  const screen = (() => {
    if (tab === 'home')     return <HomeScreen items={items} onToggle={toggleItem} />;
    if (tab === 'records')  return <RecordsScreen />;
    if (tab === 'stats')    return <StatsScreen />;
    if (tab === 'settings') return <SettingsScreen />;
    return null;
  })();

  return (
    <AndroidDevice width={360} height={760}>
      <div style={{
        height: '100%', background: '#F4F5F7',
        display: 'flex', flexDirection: 'column',
        fontFamily: 'var(--font-sans)', color: 'var(--label-strong)',
        position: 'relative', overflow: 'hidden',
      }}>
        <TopBar />
        <div ref={scrollRef} style={{ flex: 1, overflow: 'auto' }}>
          {screen}
        </div>
        <BottomNav
          active={tab}
          onChange={setTab}
          onFab={() => setFabOpen(true)}
        />

        {/* 등록 시트 */}
        {fabOpen && <RegisterSheet
          onClose={() => setFabOpen(false)}
          onMeal={() => { setFabOpen(false); setMealOpen(true); }}
          onMed={() => { setFabOpen(false); setMedOpen(true); }}
        />}
        {mealOpen && <MealRegisterSheet onClose={() => setMealOpen(false)} />}
        {medOpen && <MedRegisterSheet onClose={() => setMedOpen(false)} />}
      </div>
    </AndroidDevice>
  );
}

// ─── Register bottom sheet ────────────────────────────────────────
function RegisterSheet({ onClose, onMeal, onMed }) {
  return (
    <div style={{
      position: 'absolute', inset: 0,
      background: 'rgba(23,23,25,0.40)',
      display: 'flex', flexDirection: 'column', justifyContent: 'flex-end',
      animation: 'fadeIn 200ms ease-out',
      zIndex: 10,
    }} onClick={onClose}>
      <style>{`
        @keyframes fadeIn { from { opacity: 0 } to { opacity: 1 } }
        @keyframes slideUp { from { transform: translateY(100%) } to { transform: translateY(0) } }
      `}</style>
      <div onClick={(e) => e.stopPropagation()} style={{
        background: '#fff',
        borderTopLeftRadius: 20, borderTopRightRadius: 20,
        padding: '8px 0 24px',
        animation: 'slideUp 240ms var(--ease-emphasized)',
      }}>
        {/* drag handle */}
        <div style={{
          width: 40, height: 4, borderRadius: 999,
          background: 'var(--line-normal-normal)',
          margin: '6px auto 14px',
        }}/>
        <div style={{
          padding: '0 24px 14px',
          fontFamily: 'var(--font-display)',
          fontSize: 19, fontWeight: 700,
          color: 'var(--label-strong)', letterSpacing: '-0.018em',
        }}>새로 등록하기</div>

        <RegisterOption
          icon={(
            <g>
              <rect x="3" y="9" width="18" height="6" rx="3" transform="rotate(-30 12 12)"/>
              <path d="M8.6 7.4l4.2 7.3"/>
            </g>
          )}
          title="복용 약 등록"
          subtitle="처방받은 약을 추가합니다"
          onClick={onMed}
        />
        <RegisterOption
          icon={(
            <g>
              <path d="M6 3v8a3 3 0 0 0 3 3v7"/>
              <path d="M9 3v6"/>
              <path d="M15 3c-1.5 0-3 1.5-3 4s1.5 4 3 4h.5V21H18V3z"/>
            </g>
          )}
          title="식사 일정 등록"
          subtitle="아침 · 점심 · 저녁 시간을 정합니다"
          onClick={onMeal}
        />
        <RegisterOption
          icon={(
            <g>
              <rect x="3" y="5" width="18" height="14" rx="2"/>
              <path d="M3 8h18"/>
              <path d="M8 13l2 2 4-4"/>
            </g>
          )}
          title="처방전 스캔"
          subtitle="사진 한 장으로 자동 입력"
          onClick={onClose}
          badge="새 기능"
        />
      </div>
    </div>
  );
}

function RegisterOption({ icon, title, subtitle, badge, onClick }) {
  return (
    <button onClick={onClick} style={{
      width: '100%', display: 'flex', alignItems: 'center', gap: 14,
      padding: '14px 24px',
      border: 'none', background: 'transparent',
      cursor: 'pointer', textAlign: 'left', fontFamily: 'inherit',
    }}>
      <div style={{
        width: 44, height: 44, borderRadius: 12,
        background: 'rgba(0,102,255,0.08)',
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        color: 'var(--primary-normal)', flexShrink: 0,
      }}>
        <svg width="22" height="22" viewBox="0 0 24 24" fill="none"
          stroke="currentColor" strokeWidth="1.8"
          strokeLinecap="round" strokeLinejoin="round">{icon}</svg>
      </div>
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{
          display: 'flex', alignItems: 'center', gap: 8,
          fontSize: 14.5, fontWeight: 700,
          color: 'var(--label-strong)', letterSpacing: '-0.005em',
        }}>
          {title}
          {badge && (
            <span style={{
              fontSize: 10, fontWeight: 700, letterSpacing: '0.02em',
              color: 'var(--primary-normal)',
              background: 'rgba(0,102,255,0.10)',
              padding: '2px 6px', borderRadius: 999,
            }}>{badge}</span>
          )}
        </div>
        <div style={{
          marginTop: 2, fontSize: 11.5, fontWeight: 500,
          color: 'var(--label-neutral)', letterSpacing: '-0.002em',
        }}>{subtitle}</div>
      </div>
      <span style={{ color: 'var(--label-alternative)', display: 'flex' }}>
        <ChevronRight />
      </span>
    </button>
  );
}

// ─── Meal Register Sheet — 식사 일정 등록 ──────────────────────────
const MEAL_PRESETS = [
  { name: '아침', time: '08:30' },
  { name: '점심', time: '12:30' },
  { name: '저녁', time: '18:30' },
];
const DAY_OPTIONS = [
  { id: 'mon', label: '월' },
  { id: 'tue', label: '화' },
  { id: 'wed', label: '수' },
  { id: 'thu', label: '목' },
  { id: 'fri', label: '금' },
  { id: 'sat', label: '토' },
  { id: 'sun', label: '일' },
];

function MealRegisterSheet({ onClose }) {
  const [name, setName] = React.useState('');
  const [time, setTime] = React.useState('08:30');
  const [days, setDays] = React.useState(new Set(['mon','tue','wed','thu','fri','sat','sun']));
  const [guardianCanDefer, setGuardianCanDefer] = React.useState(true);

  const toggleDay = (id) => {
    const next = new Set(days);
    if (next.has(id)) next.delete(id); else next.add(id);
    setDays(next);
  };
  const everyDay = days.size === 7;
  const weekdays = ['mon','tue','wed','thu','fri'];
  const isWeekday = days.size === 5 && weekdays.every(d => days.has(d));
  const canSave = name.trim().length > 0 && days.size > 0;

  return (
    <div style={{
      position: 'absolute', inset: 0,
      background: 'rgba(23,23,25,0.40)',
      display: 'flex', flexDirection: 'column', justifyContent: 'flex-end',
      animation: 'fadeIn 200ms ease-out',
      zIndex: 11,
    }} onClick={onClose}>
      <div onClick={(e) => e.stopPropagation()} style={{
        background: '#fff',
        borderTopLeftRadius: 20, borderTopRightRadius: 20,
        padding: '8px 0 24px',
        animation: 'slideUp 260ms var(--ease-emphasized)',
        maxHeight: '92%', display: 'flex', flexDirection: 'column',
      }}>
        {/* drag handle */}
        <div style={{
          width: 40, height: 4, borderRadius: 999,
          background: 'var(--line-normal-normal)',
          margin: '6px auto 14px', flexShrink: 0,
        }}/>

        {/* header */}
        <div style={{
          padding: '0 24px 18px',
          display: 'flex', alignItems: 'baseline', justifyContent: 'space-between',
          flexShrink: 0,
        }}>
          <div style={{
            fontFamily: 'var(--font-display)',
            fontSize: 19, fontWeight: 700,
            color: 'var(--label-strong)', letterSpacing: '-0.018em',
          }}>식사 일정 등록</div>
          <button onClick={onClose} style={{
            background: 'transparent', border: 'none', cursor: 'pointer',
            fontSize: 13, fontWeight: 600,
            color: 'var(--label-neutral)',
            fontFamily: 'inherit', padding: 0,
          }}>취소</button>
        </div>

        <div style={{
          flex: 1, overflowY: 'auto',
          padding: '0 24px',
        }}>
          {/* 식사 이름 */}
          <div style={{ marginBottom: 22 }}>
            <FieldLabel>식사 이름</FieldLabel>
            <input
              type="text"
              value={name}
              onChange={(e) => setName(e.target.value)}
              placeholder="예: 아침"
              style={{
                width: '100%', boxSizing: 'border-box',
                padding: '12px 14px',
                border: '1px solid var(--line-normal-normal)',
                borderRadius: 12,
                fontSize: 14, fontWeight: 500,
                color: 'var(--label-strong)',
                fontFamily: 'inherit',
                letterSpacing: '-0.005em',
                outline: 'none',
                background: '#fff',
              }}
              onFocus={(e) => e.target.style.borderColor = 'var(--primary-normal)'}
              onBlur={(e) => e.target.style.borderColor = 'var(--line-normal-normal)'}
            />
            <div style={{
              marginTop: 10, display: 'flex', gap: 6, flexWrap: 'wrap',
            }}>
              {MEAL_PRESETS.map((p) => {
                const active = name === p.name;
                return (
                  <button key={p.name} onClick={() => { setName(p.name); setTime(p.time); }}
                    style={{
                      padding: '6px 12px', borderRadius: 999,
                      border: active ? '1px solid var(--primary-normal)'
                                     : '1px solid var(--line-normal-normal)',
                      background: active ? 'rgba(0,102,255,0.06)' : '#fff',
                      color: active ? 'var(--primary-normal)' : 'var(--label-neutral)',
                      fontSize: 12, fontWeight: 600,
                      cursor: 'pointer', fontFamily: 'inherit',
                      letterSpacing: '-0.005em',
                    }}>{p.name}</button>
                );
              })}
            </div>
          </div>

          {/* 시간 */}
          <div style={{ marginBottom: 22 }}>
            <FieldLabel>시간</FieldLabel>
            <div style={{
              padding: '12px 14px',
              border: '1px solid var(--line-normal-normal)',
              borderRadius: 12,
              display: 'flex', alignItems: 'center', gap: 12,
              background: '#fff',
            }}>
              <input
                type="time"
                value={time}
                onChange={(e) => setTime(e.target.value)}
                style={{
                  flex: 1, border: 'none', outline: 'none',
                  fontSize: 18, fontWeight: 700,
                  fontFamily: 'var(--font-display)',
                  color: 'var(--label-strong)',
                  letterSpacing: '-0.012em',
                  fontVariantNumeric: 'tabular-nums',
                  background: 'transparent',
                  padding: 0,
                }}/>
              <span style={{
                fontSize: 11.5, fontWeight: 700, letterSpacing: '0.02em',
                color: 'var(--label-alternative)',
              }}>{periodOf(time)}</span>
            </div>
          </div>

          {/* 요일 */}
          <div style={{ marginBottom: 22 }}>
            <div style={{
              display: 'flex', alignItems: 'baseline', justifyContent: 'space-between',
              marginBottom: 10,
            }}>
              <FieldLabel inline>요일</FieldLabel>
              <div style={{ display: 'flex', gap: 6 }}>
                <QuickBtn active={everyDay}
                  onClick={() => setDays(new Set(DAY_OPTIONS.map(d=>d.id)))}>매일</QuickBtn>
                <QuickBtn active={isWeekday}
                  onClick={() => setDays(new Set(weekdays))}>평일</QuickBtn>
              </div>
            </div>
            <div style={{
              display: 'grid', gridTemplateColumns: 'repeat(7, 1fr)', gap: 6,
            }}>
              {DAY_OPTIONS.map((d) => {
                const active = days.has(d.id);
                const isSun = d.id === 'sun';
                return (
                  <button key={d.id} onClick={() => toggleDay(d.id)} style={{
                    aspectRatio: '1 / 1',
                    border: 'none',
                    borderRadius: 10,
                    background: active ? 'var(--primary-normal)' : 'var(--fill-alternative)',
                    color: active ? '#fff'
                      : isSun ? 'var(--status-cautionary)' : 'var(--label-neutral)',
                    cursor: 'pointer', fontFamily: 'inherit',
                    fontSize: 13, fontWeight: 700,
                    letterSpacing: '-0.005em',
                    boxShadow: active ? '0 2px 6px rgba(0,102,255,0.22)' : 'none',
                    transition: 'all 150ms',
                  }}>{d.label}</button>
                );
              })}
            </div>
          </div>

          {/* 보호자 권한 */}
          <div style={{ marginBottom: 8 }}>
            <FieldLabel>권한</FieldLabel>
            <button onClick={() => setGuardianCanDefer(!guardianCanDefer)} style={{
              width: '100%',
              display: 'flex', alignItems: 'flex-start', gap: 12,
              padding: '14px 14px',
              border: '1px solid var(--line-normal-normal)',
              borderRadius: 12,
              background: '#fff',
              cursor: 'pointer', textAlign: 'left',
              fontFamily: 'inherit',
            }}>
              {/* checkbox */}
              <div style={{
                width: 22, height: 22, borderRadius: 6,
                flexShrink: 0, marginTop: 1,
                background: guardianCanDefer ? 'var(--primary-normal)' : 'transparent',
                border: guardianCanDefer ? 'none' : '1.5px solid var(--line-normal-normal)',
                boxSizing: 'border-box',
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                transition: 'all 150ms',
              }}>
                {guardianCanDefer && (
                  <svg width="12" height="12" viewBox="0 0 24 24" fill="none"
                    stroke="#fff" strokeWidth="3" strokeLinecap="round" strokeLinejoin="round">
                    <path d="M5 12.5l4.5 4.5L20 7"/>
                  </svg>
                )}
              </div>
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{
                  fontSize: 13.5, fontWeight: 600,
                  color: 'var(--label-strong)', letterSpacing: '-0.005em',
                }}>보호자가 일정을 미룰 수 있게 할까요?</div>
                <div style={{
                  marginTop: 3, fontSize: 11.5, fontWeight: 500,
                  color: 'var(--label-neutral)', letterSpacing: '-0.002em',
                  lineHeight: 1.45,
                }}>식사 시간을 30분~2시간 미룰 수 있어요.</div>
              </div>
            </button>
          </div>
        </div>

        {/* CTA */}
        <div style={{
          padding: '14px 24px 0', flexShrink: 0,
          borderTop: '1px solid var(--line-normal-neutral)',
          marginTop: 14,
        }}>
          <button onClick={onClose} disabled={!canSave} style={{
            width: '100%', padding: '14px 0',
            background: canSave ? 'var(--primary-normal)' : 'var(--fill-alternative)',
            color: canSave ? '#fff' : 'var(--label-alternative)',
            border: 'none', borderRadius: 12,
            fontSize: 15, fontWeight: 700,
            letterSpacing: '-0.005em',
            cursor: canSave ? 'pointer' : 'default',
            fontFamily: 'inherit',
            boxShadow: canSave ? '0 6px 14px rgba(0,102,255,0.24)' : 'none',
            transition: 'all 150ms',
          }}>저장</button>
        </div>
      </div>
    </div>
  );
}

function FieldLabel({ children, inline }) {
  return (
    <div style={{
      marginBottom: inline ? 0 : 10,
      fontSize: 11.5, fontWeight: 700, letterSpacing: '0.1em',
      color: 'var(--label-neutral)', textTransform: 'uppercase',
    }}>{children}</div>
  );
}

function QuickBtn({ children, active, onClick }) {
  return (
    <button onClick={onClick} style={{
      padding: '5px 10px', borderRadius: 999,
      border: active ? '1px solid var(--primary-normal)'
                     : '1px solid var(--line-normal-normal)',
      background: active ? 'rgba(0,102,255,0.08)' : '#fff',
      color: active ? 'var(--primary-normal)' : 'var(--label-neutral)',
      fontSize: 11, fontWeight: 700,
      cursor: 'pointer', fontFamily: 'inherit',
      letterSpacing: '-0.005em',
    }}>{children}</button>
  );
}

function periodOf(time) {
  const [h] = time.split(':').map(Number);
  if (h < 11) return '아침';
  if (h < 14) return '점심';
  if (h < 17) return '오후';
  if (h < 21) return '저녁';
  return '밤';
}

// ─── Med Register Sheet — 복용 약 등록 (식사 기반) ──────────────────
// 식사 일정은 실제 앱에선 등록된 식사 목록에서 가져와야 함
const REGISTERED_MEALS = [
  { id: 'breakfast', name: '아침', time: '08:30' },
  { id: 'lunch',     name: '점심', time: '12:30' },
  { id: 'dinner',    name: '저녁', time: '18:30' },
];

const TIMING_OPTIONS = [
  { id: 'before',  label: '식전', offsetMin: -30 },
  { id: 'after',   label: '식후', offsetMin: 30 },
];

function addMinutes(time, mins) {
  const [h, m] = time.split(':').map(Number);
  const total = h * 60 + m + mins;
  const hh = Math.floor((total + 24*60) % (24*60) / 60);
  const mm = (total + 24*60) % 60;
  return `${String(hh).padStart(2,'0')}:${String(mm).padStart(2,'0')}`;
}

function MedRegisterSheet({ onClose }) {
  const [name, setName] = React.useState('');
  const [dose, setDose] = React.useState('');
  const [meals, setMeals] = React.useState(new Set()); // breakfast/lunch/dinner
  const [timings, setTimings] = React.useState(new Set(['after'])); // before/after — 다중
  const [guardianCanDefer, setGuardianCanDefer] = React.useState(true);

  const toggleMeal = (id) => {
    const next = new Set(meals);
    if (next.has(id)) next.delete(id); else next.add(id);
    setMeals(next);
  };
  const toggleTiming = (id) => {
    const next = new Set(timings);
    if (next.has(id)) next.delete(id); else next.add(id);
    setTimings(next);
  };

  const canSave = name.trim().length > 0 && meals.size > 0 && timings.size > 0;

  // Preview: 어떤 시각에 알림이 울리는지
  const preview = [];
  REGISTERED_MEALS.forEach(m => {
    if (!meals.has(m.id)) return;
    TIMING_OPTIONS.forEach(t => {
      if (!timings.has(t.id)) return;
      preview.push({
        mealName: m.name,
        timingLabel: t.label,
        time: addMinutes(m.time, t.offsetMin),
      });
    });
  });
  // 시간 순 정렬
  preview.sort((a, b) => a.time.localeCompare(b.time));

  return (
    <div style={{
      position: 'absolute', inset: 0,
      background: 'rgba(23,23,25,0.40)',
      display: 'flex', flexDirection: 'column', justifyContent: 'flex-end',
      animation: 'fadeIn 200ms ease-out',
      zIndex: 11,
    }} onClick={onClose}>
      <div onClick={(e) => e.stopPropagation()} style={{
        background: '#fff',
        borderTopLeftRadius: 20, borderTopRightRadius: 20,
        padding: '8px 0 24px',
        animation: 'slideUp 260ms var(--ease-emphasized)',
        maxHeight: '92%', display: 'flex', flexDirection: 'column',
      }}>
        <div style={{
          width: 40, height: 4, borderRadius: 999,
          background: 'var(--line-normal-normal)',
          margin: '6px auto 14px', flexShrink: 0,
        }}/>

        <div style={{
          padding: '0 24px 18px',
          display: 'flex', alignItems: 'baseline', justifyContent: 'space-between',
          flexShrink: 0,
        }}>
          <div style={{
            fontFamily: 'var(--font-display)',
            fontSize: 19, fontWeight: 700,
            color: 'var(--label-strong)', letterSpacing: '-0.018em',
          }}>복용 약 등록</div>
          <button onClick={onClose} style={{
            background: 'transparent', border: 'none', cursor: 'pointer',
            fontSize: 13, fontWeight: 600,
            color: 'var(--label-neutral)',
            fontFamily: 'inherit', padding: 0,
          }}>취소</button>
        </div>

        <div style={{
          flex: 1, overflowY: 'auto',
          padding: '0 24px',
        }}>
          {/* 약 이름 */}
          <div style={{ marginBottom: 18 }}>
            <FieldLabel>약 이름</FieldLabel>
            <input
              type="text"
              value={name}
              onChange={(e) => setName(e.target.value)}
              placeholder="예: 암로디핀"
              style={{
                width: '100%', boxSizing: 'border-box',
                padding: '12px 14px',
                border: '1px solid var(--line-normal-normal)',
                borderRadius: 12,
                fontSize: 14, fontWeight: 500,
                color: 'var(--label-strong)',
                fontFamily: 'inherit',
                letterSpacing: '-0.005em',
                outline: 'none',
                background: '#fff',
              }}
              onFocus={(e) => e.target.style.borderColor = 'var(--primary-normal)'}
              onBlur={(e) => e.target.style.borderColor = 'var(--line-normal-normal)'}
            />
          </div>

          {/* 용량 */}
          <div style={{ marginBottom: 22 }}>
            <FieldLabel>용량</FieldLabel>
            <input
              type="text"
              value={dose}
              onChange={(e) => setDose(e.target.value)}
              placeholder="예: 5mg 1정"
              style={{
                width: '100%', boxSizing: 'border-box',
                padding: '12px 14px',
                border: '1px solid var(--line-normal-normal)',
                borderRadius: 12,
                fontSize: 14, fontWeight: 500,
                color: 'var(--label-strong)',
                fontFamily: 'inherit',
                letterSpacing: '-0.005em',
                outline: 'none',
                background: '#fff',
              }}
              onFocus={(e) => e.target.style.borderColor = 'var(--primary-normal)'}
              onBlur={(e) => e.target.style.borderColor = 'var(--line-normal-normal)'}
            />
          </div>

          {/* 복용 식사 */}
          <div style={{ marginBottom: 22 }}>
            <FieldLabel>복용 식사</FieldLabel>
            <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
              {REGISTERED_MEALS.map((m) => {
                const active = meals.has(m.id);
                return (
                  <button key={m.id} onClick={() => toggleMeal(m.id)} style={{
                    display: 'flex', alignItems: 'center', gap: 12,
                    padding: '12px 14px',
                    border: active ? '1px solid var(--primary-normal)'
                                   : '1px solid var(--line-normal-normal)',
                    borderRadius: 12,
                    background: active ? 'rgba(0,102,255,0.04)' : '#fff',
                    cursor: 'pointer', fontFamily: 'inherit',
                    textAlign: 'left', transition: 'all 150ms',
                  }}>
                    <div style={{
                      width: 22, height: 22, borderRadius: 6,
                      flexShrink: 0,
                      background: active ? 'var(--primary-normal)' : 'transparent',
                      border: active ? 'none' : '1.5px solid var(--line-normal-normal)',
                      boxSizing: 'border-box',
                      display: 'flex', alignItems: 'center', justifyContent: 'center',
                    }}>
                      {active && (
                        <svg width="12" height="12" viewBox="0 0 24 24" fill="none"
                          stroke="#fff" strokeWidth="3" strokeLinecap="round" strokeLinejoin="round">
                          <path d="M5 12.5l4.5 4.5L20 7"/>
                        </svg>
                      )}
                    </div>
                    <div style={{
                      flex: 1,
                      fontSize: 14, fontWeight: 600,
                      color: 'var(--label-strong)', letterSpacing: '-0.005em',
                    }}>{m.name}</div>
                    <div style={{
                      fontSize: 12.5, fontWeight: 500,
                      color: 'var(--label-alternative)',
                      fontVariantNumeric: 'tabular-nums', letterSpacing: '0.005em',
                    }}>{m.time}</div>
                  </button>
                );
              })}
            </div>
            <div style={{
              marginTop: 8, fontSize: 11, fontWeight: 500,
              color: 'var(--label-alternative)',
              letterSpacing: '-0.002em', lineHeight: 1.5,
            }}>등록된 식사 일정에 맞춰 복용 알림을 보냅니다.</div>
          </div>

          {/* 식전 / 식후 — 다중 선택 */}
          <div style={{ marginBottom: 18 }}>
            <FieldLabel>복용 시점</FieldLabel>
            <div style={{ display: 'flex', gap: 8 }}>
              {TIMING_OPTIONS.map((t) => {
                const active = timings.has(t.id);
                return (
                  <button key={t.id} onClick={() => toggleTiming(t.id)} style={{
                    flex: 1,
                    display: 'flex', alignItems: 'center', justifyContent: 'center',
                    gap: 8,
                    padding: '12px 0',
                    border: active ? '1px solid var(--primary-normal)'
                                   : '1px solid var(--line-normal-normal)',
                    borderRadius: 12,
                    background: active ? 'rgba(0,102,255,0.04)' : '#fff',
                    cursor: 'pointer', fontFamily: 'inherit',
                    transition: 'all 150ms',
                  }}>
                    <div style={{
                      width: 20, height: 20, borderRadius: 6,
                      flexShrink: 0,
                      background: active ? 'var(--primary-normal)' : 'transparent',
                      border: active ? 'none' : '1.5px solid var(--line-normal-normal)',
                      boxSizing: 'border-box',
                      display: 'flex', alignItems: 'center', justifyContent: 'center',
                    }}>
                      {active && (
                        <svg width="11" height="11" viewBox="0 0 24 24" fill="none"
                          stroke="#fff" strokeWidth="3" strokeLinecap="round" strokeLinejoin="round">
                          <path d="M5 12.5l4.5 4.5L20 7"/>
                        </svg>
                      )}
                    </div>
                    <span style={{
                      fontSize: 13.5, fontWeight: active ? 700 : 600,
                      color: active ? 'var(--label-strong)' : 'var(--label-neutral)',
                      letterSpacing: '-0.005em',
                    }}>{t.label} 30분</span>
                  </button>
                );
              })}
            </div>
          </div>

          {/* 미리보기 */}
          {preview.length > 0 && (
            <div style={{
              marginBottom: 22, padding: '14px 16px',
              background: 'rgba(0,102,255,0.04)',
              border: '1px solid rgba(0,102,255,0.18)',
              borderRadius: 12,
            }}>
              <div style={{
                fontSize: 11, fontWeight: 700, letterSpacing: '0.08em',
                color: 'var(--primary-normal)', textTransform: 'uppercase',
                marginBottom: 8,
              }}>알림 시각</div>
              <div style={{ display: 'flex', flexDirection: 'column', gap: 4 }}>
                {preview.map((p, i) => (
                  <div key={i} style={{
                    display: 'flex', alignItems: 'baseline', justifyContent: 'space-between',
                    fontSize: 13, fontWeight: 500,
                    color: 'var(--label-strong)',
                    letterSpacing: '-0.005em',
                  }}>
                    <span>{p.mealName} {p.timingLabel} 30분</span>
                    <span style={{
                      fontWeight: 700, color: 'var(--primary-normal)',
                      fontVariantNumeric: 'tabular-nums',
                    }}>{p.time}</span>
                  </div>
                ))}
              </div>
            </div>
          )}

          {/* 보호자 권한 */}
          <div style={{ marginBottom: 8 }}>
            <FieldLabel>권한</FieldLabel>
            <button onClick={() => setGuardianCanDefer(!guardianCanDefer)} style={{
              width: '100%',
              display: 'flex', alignItems: 'flex-start', gap: 12,
              padding: '14px 14px',
              border: '1px solid var(--line-normal-normal)',
              borderRadius: 12,
              background: '#fff',
              cursor: 'pointer', textAlign: 'left',
              fontFamily: 'inherit',
            }}>
              <div style={{
                width: 22, height: 22, borderRadius: 6,
                flexShrink: 0, marginTop: 1,
                background: guardianCanDefer ? 'var(--primary-normal)' : 'transparent',
                border: guardianCanDefer ? 'none' : '1.5px solid var(--line-normal-normal)',
                boxSizing: 'border-box',
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                transition: 'all 150ms',
              }}>
                {guardianCanDefer && (
                  <svg width="12" height="12" viewBox="0 0 24 24" fill="none"
                    stroke="#fff" strokeWidth="3" strokeLinecap="round" strokeLinejoin="round">
                    <path d="M5 12.5l4.5 4.5L20 7"/>
                  </svg>
                )}
              </div>
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{
                  fontSize: 13.5, fontWeight: 600,
                  color: 'var(--label-strong)', letterSpacing: '-0.005em',
                }}>보호자가 일정을 미룰 수 있게 할까요?</div>
                <div style={{
                  marginTop: 3, fontSize: 11.5, fontWeight: 500,
                  color: 'var(--label-neutral)', letterSpacing: '-0.002em',
                  lineHeight: 1.45,
                }}>복용 시각을 30분~2시간 미룰 수 있어요.</div>
              </div>
            </button>
          </div>
        </div>

        {/* CTA */}
        <div style={{
          padding: '14px 24px 0', flexShrink: 0,
          borderTop: '1px solid var(--line-normal-neutral)',
          marginTop: 14,
        }}>
          <button onClick={onClose} disabled={!canSave} style={{
            width: '100%', padding: '14px 0',
            background: canSave ? 'var(--primary-normal)' : 'var(--fill-alternative)',
            color: canSave ? '#fff' : 'var(--label-alternative)',
            border: 'none', borderRadius: 12,
            fontSize: 15, fontWeight: 700,
            letterSpacing: '-0.005em',
            cursor: canSave ? 'pointer' : 'default',
            fontFamily: 'inherit',
            boxShadow: canSave ? '0 6px 14px rgba(0,102,255,0.24)' : 'none',
            transition: 'all 150ms',
          }}>저장</button>
        </div>
      </div>
    </div>
  );
}

ReactDOM.createRoot(document.getElementById('mount')).render(<App />);
