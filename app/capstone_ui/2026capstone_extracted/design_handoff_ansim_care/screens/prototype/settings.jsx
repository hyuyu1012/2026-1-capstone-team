// ─── Settings screen ──────────────────────────────────────────────
function SettingsScreen() {
  const [notif, setNotif] = React.useState({
    reminder: true,
    missed: true,
    guardian: true,
    sound: true,
  });
  const [fontSize, setFontSize] = React.useState(2); // 0: 작게, 1: 보통, 2: 크게, 3: 매우 크게
  const [darkMode, setDarkMode] = React.useState(false);

  return (
    <div style={{ padding: '4px 24px 32px' }}>
      <PageHeader title="설정" />

      {/* 환자 프로필 카드 */}
      <div style={{
        marginTop: 20, padding: '20px 18px',
        border: '1px solid var(--line-normal-neutral)',
        borderRadius: 16, background: '#fff',
        display: 'flex', alignItems: 'center', gap: 14,
      }}>
        <div style={{
          width: 56, height: 56, borderRadius: 999,
          background: 'linear-gradient(135deg, #4F95FF 0%, #0066FF 100%)',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          color: '#fff',
          fontFamily: 'var(--font-display)',
          fontSize: 22, fontWeight: 700, letterSpacing: '-0.01em',
          flexShrink: 0,
        }}>{PATIENT.profileInitial}</div>
        <div style={{ flex: 1, minWidth: 0 }}>
          <div style={{
            fontSize: 17, fontWeight: 700,
            color: 'var(--label-strong)', letterSpacing: '-0.012em',
          }}>{PATIENT.name}</div>
          <div style={{
            marginTop: 2, fontSize: 12.5, fontWeight: 500,
            color: 'var(--label-neutral)', letterSpacing: '-0.002em',
          }}>{PATIENT.relation} · 만 {PATIENT.age}세</div>
        </div>
        <button style={{
          padding: '8px 14px', border: '1px solid var(--line-normal-normal)',
          background: '#fff', borderRadius: 999,
          fontSize: 12, fontWeight: 700,
          color: 'var(--label-strong)',
          cursor: 'pointer', fontFamily: 'inherit',
          letterSpacing: '-0.005em',
        }}>편집</button>
      </div>

      {/* 알림 */}
      <SettingsSection title="알림" topMargin={24}>
        <SettingsRow
          label="복용 알림"
          subtitle="예정 시간에 알림을 보냅니다"
          control={<Toggle value={notif.reminder} onChange={v => setNotif({...notif, reminder: v})}/>}
          first
        />
        <SettingsRow
          label="누락 알림"
          subtitle="30분 이상 지나면 다시 알려요"
          control={<Toggle value={notif.missed} onChange={v => setNotif({...notif, missed: v})}/>}
        />
        <SettingsRow
          label="보호자에게 푸시"
          subtitle="누락 시 가족에게 알림"
          control={<Toggle value={notif.guardian} onChange={v => setNotif({...notif, guardian: v})}/>}
        />
        <SettingsRow
          label="알림음"
          subtitle="기본 · 부드러운 차임"
          control={<Toggle value={notif.sound} onChange={v => setNotif({...notif, sound: v})}/>}
        />
      </SettingsSection>

      {/* 복용 정보 */}
      <SettingsSection title="복용 정보">
        <NavRow
          label="복용 일정 관리"
          right={<span style={{
            fontSize: 12, fontWeight: 700, color: 'var(--label-alternative)',
            fontVariantNumeric: 'tabular-nums', marginRight: 6,
          }}>{MEDS.length}개</span>}
          first
        />
        <NavRow label="식사 시간 설정" right={
          <span style={{
            fontSize: 12, fontWeight: 600, color: 'var(--label-alternative)',
            fontVariantNumeric: 'tabular-nums', marginRight: 6,
          }}>08:30 · 12:30 · 18:30</span>
        }/>
        <NavRow label="처방 기록" subtitle="병원 / 처방전 사진 보관" />
      </SettingsSection>

      {/* 가족 / 보호자 */}
      <SettingsSection title="가족 · 보호자">
        <GuardianRow name="이지원" relation="딸" status="활성" first />
        <GuardianRow name="이정훈" relation="아들" status="활성" />
        <NavRow label="보호자 초대" tone="primary" />
      </SettingsSection>

      {/* 화면 */}
      <SettingsSection title="화면">
        <SettingsRow
          label="다크 모드"
          control={<Toggle value={darkMode} onChange={setDarkMode}/>}
          first
        />
        <div style={{
          padding: '14px 18px',
          borderTop: '1px solid var(--line-normal-neutral)',
        }}>
          <div style={{
            display: 'flex', alignItems: 'baseline', justifyContent: 'space-between',
            marginBottom: 10,
          }}>
            <div style={{
              fontSize: 14, fontWeight: 600,
              color: 'var(--label-strong)', letterSpacing: '-0.005em',
            }}>글자 크기</div>
            <div style={{
              fontSize: 11.5, fontWeight: 700,
              color: 'var(--primary-normal)', letterSpacing: '0.02em',
            }}>{['작게','보통','크게','매우 크게'][fontSize]}</div>
          </div>
          <FontSizePicker value={fontSize} onChange={setFontSize} />
        </div>
      </SettingsSection>

      {/* 일반 */}
      <SettingsSection title="일반">
        <NavRow label="개인정보 및 데이터" first />
        <NavRow label="도움말 · 문의" />
        <NavRow label="앱 정보" right={
          <span style={{
            fontSize: 12, fontWeight: 500, color: 'var(--label-alternative)',
            fontVariantNumeric: 'tabular-nums', marginRight: 6,
          }}>v1.0.0</span>
        }/>
      </SettingsSection>

      <button style={{
        marginTop: 16, width: '100%',
        padding: '14px 18px',
        background: '#fff',
        border: '1px solid var(--line-normal-neutral)',
        borderRadius: 14,
        fontSize: 14, fontWeight: 600,
        color: 'var(--status-negative)',
        cursor: 'pointer', fontFamily: 'inherit',
        letterSpacing: '-0.005em',
      }}>로그아웃</button>
    </div>
  );
}

function SettingsSection({ title, children, topMargin = 18 }) {
  return (
    <div style={{ marginTop: topMargin }}>
      <div style={{
        padding: '0 4px 8px',
        fontSize: 11.5, fontWeight: 700, letterSpacing: '0.1em',
        color: 'var(--label-neutral)', textTransform: 'uppercase',
      }}>{title}</div>
      <div style={{
        background: '#fff', borderRadius: 14,
        border: '1px solid var(--line-normal-neutral)',
        overflow: 'hidden',
      }}>{children}</div>
    </div>
  );
}

function SettingsRow({ label, subtitle, control, first }) {
  return (
    <div style={{
      padding: '14px 18px', display: 'flex', alignItems: 'center', gap: 12,
      borderTop: first ? 'none' : '1px solid var(--line-normal-neutral)',
    }}>
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{
          fontSize: 14, fontWeight: 600,
          color: 'var(--label-strong)', letterSpacing: '-0.005em',
        }}>{label}</div>
        {subtitle && (
          <div style={{
            marginTop: 2, fontSize: 11.5, fontWeight: 500,
            color: 'var(--label-neutral)', letterSpacing: '-0.002em',
          }}>{subtitle}</div>
        )}
      </div>
      {control}
    </div>
  );
}

function NavRow({ label, subtitle, right, first, tone, onClick }) {
  const isPrimary = tone === 'primary';
  return (
    <button onClick={onClick} style={{
      width: '100%',
      padding: '14px 18px',
      display: 'flex', alignItems: 'center', gap: 8,
      borderTop: first ? 'none' : '1px solid var(--line-normal-neutral)',
      borderLeft: 'none', borderRight: 'none', borderBottom: 'none',
      background: 'transparent',
      cursor: 'pointer', textAlign: 'left', fontFamily: 'inherit',
    }}>
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{
          fontSize: 14, fontWeight: isPrimary ? 700 : 600,
          color: isPrimary ? 'var(--primary-normal)' : 'var(--label-strong)',
          letterSpacing: '-0.005em',
        }}>{isPrimary && '+ '}{label}</div>
        {subtitle && (
          <div style={{
            marginTop: 2, fontSize: 11.5, fontWeight: 500,
            color: 'var(--label-neutral)', letterSpacing: '-0.002em',
          }}>{subtitle}</div>
        )}
      </div>
      {right}
      {!isPrimary && (
        <span style={{ color: 'var(--label-alternative)', display: 'flex' }}>
          <ChevronRight />
        </span>
      )}
    </button>
  );
}

function GuardianRow({ name, relation, status, first }) {
  return (
    <div style={{
      padding: '12px 18px', display: 'flex', alignItems: 'center', gap: 12,
      borderTop: first ? 'none' : '1px solid var(--line-normal-neutral)',
    }}>
      <div style={{
        width: 36, height: 36, borderRadius: 999,
        background: 'var(--fill-alternative)',
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        color: 'var(--label-neutral)',
        fontFamily: 'var(--font-display)',
        fontSize: 14, fontWeight: 700,
      }}>{name[0]}</div>
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{
          fontSize: 14, fontWeight: 600,
          color: 'var(--label-strong)', letterSpacing: '-0.005em',
        }}>{name}</div>
        <div style={{
          marginTop: 1, fontSize: 11.5, fontWeight: 500,
          color: 'var(--label-neutral)',
        }}>{relation}</div>
      </div>
      <span style={{
        fontSize: 11, fontWeight: 700, letterSpacing: '0.02em',
        color: 'var(--c-green-40)',
        background: 'rgba(0,191,64,0.10)',
        padding: '4px 8px', borderRadius: 999,
      }}>{status}</span>
    </div>
  );
}

function Toggle({ value, onChange }) {
  return (
    <button onClick={() => onChange(!value)} style={{
      width: 44, height: 26, borderRadius: 999,
      background: value ? 'var(--primary-normal)' : 'var(--fill-normal)',
      border: 'none', padding: 0, cursor: 'pointer',
      position: 'relative', flexShrink: 0,
      transition: 'background 180ms var(--ease-standard)',
    }}>
      <div style={{
        position: 'absolute', top: 2,
        left: value ? 20 : 2,
        width: 22, height: 22, borderRadius: 999,
        background: '#fff',
        boxShadow: '0 1px 3px rgba(0,0,0,0.15)',
        transition: 'left 180ms var(--ease-standard)',
      }}/>
    </button>
  );
}

function FontSizePicker({ value, onChange }) {
  const labels = ['가', '가', '가', '가'];
  const sizes = [12, 14, 16, 19];
  return (
    <div style={{
      display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 6,
    }}>
      {labels.map((l, i) => {
        const active = value === i;
        return (
          <button key={i} onClick={() => onChange(i)} style={{
            padding: '10px 0', borderRadius: 10,
            background: active ? 'var(--primary-normal)' : 'var(--fill-alternative)',
            border: 'none', cursor: 'pointer', fontFamily: 'inherit',
            fontSize: sizes[i], fontWeight: 700,
            color: active ? '#fff' : 'var(--label-neutral)',
            transition: 'all 150ms',
          }}>{l}</button>
        );
      })}
    </div>
  );
}

Object.assign(window, { SettingsScreen });
