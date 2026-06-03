// ─── App (tab router) ─────────────────────────────────────────────
function App() {
  const [tab, setTab] = React.useState('home');
  const [items, setItems] = React.useState(INITIAL_TODAY);
  const [fabOpen, setFabOpen] = React.useState(false);
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
        {fabOpen && <RegisterSheet onClose={() => setFabOpen(false)} />}
      </div>
    </AndroidDevice>
  );
}

// ─── Register bottom sheet ────────────────────────────────────────
function RegisterSheet({ onClose }) {
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
          onClick={onClose}
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
          onClick={onClose}
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

ReactDOM.createRoot(document.getElementById('mount')).render(<App />);
