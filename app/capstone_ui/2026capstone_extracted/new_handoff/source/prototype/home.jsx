// ─── Home screen (v7 — 주간 막대그래프) ──────────────────────────
const WEEK_DAYS = [
  { label: '월', date: 25, value: MONTH_DATA[24] },
  { label: '화', date: 26, value: MONTH_DATA[25] },
  { label: '수', date: 27, value: null, isToday: true },
  { label: '목', date: 28, value: MONTH_DATA[27] },
  { label: '금', date: 29, value: MONTH_DATA[28] },
  { label: '토', date: 30, value: MONTH_DATA[29] },
  { label: '일', date: 31, value: MONTH_DATA[30] },
];

function HomeScreen({ items, onToggle }) {
  const done = items.filter(i => i.taken).length;
  const total = items.length;
  const todayPct = done / total;

  const weekAvg = (() => {
    const vals = WEEK_DAYS.map(d => d.isToday ? todayPct : d.value)
      .filter(v => v !== null && v !== undefined);
    return vals.length ? vals.reduce((a,b)=>a+b,0) / vals.length : 0;
  })();

  return (
    <div style={{ padding: '4px 24px 32px' }}>
      <PageHeader
        title="오늘 현황을 확인하세요"
        subtitle={`${PATIENT.relation} · ${PATIENT.name}`}
      />

      {/* 오늘 일정 카드 */}
      <div style={{
        marginTop: 24, padding: '20px 18px',
        border: '1px solid var(--line-normal-neutral)',
        borderRadius: 16, background: '#fff',
      }}>
        <div style={{ marginBottom: 16 }}>
          <span style={{
            fontSize: 11.5, fontWeight: 700, letterSpacing: '0.1em',
            color: 'var(--label-neutral)', textTransform: 'uppercase',
          }}>오늘 일정</span>
        </div>
        <TodayGrid items={items} onToggle={onToggle} />
      </div>

      {/* 복용 일정 */}
      <div style={{ marginTop: 20 }}>
        <SectionHeader right={`${done} / ${total}`}>복용 일정</SectionHeader>
        <div style={{
          background: '#fff', borderRadius: 14,
          border: '1px solid var(--line-normal-neutral)',
          overflow: 'hidden',
        }}>
          {items.map((it, i) => (
            <ScheduleRow key={it.id} item={it} first={i === 0} onToggle={() => onToggle(it.id)} />
          ))}
        </div>
      </div>
    </div>
  );
}

function WeeklyBars({ todayPct }) {
  const BAR_AREA_H = 110;
  const days = WEEK_DAYS.map(d => ({ ...d, value: d.isToday ? todayPct : d.value }));
  return (
    <div>
      <div style={{
        display: 'grid', gridTemplateColumns: 'repeat(7, 1fr)',
        gap: 6, height: BAR_AREA_H, alignItems: 'end',
      }}>
        {days.map((d, i) => {
          const v = d.value;
          const hasValue = v !== null && v !== undefined;
          const heightPct = hasValue ? Math.max(v, 0.04) * 100 : 0;
          const isToday = d.isToday;
          return (
            <div key={i} style={{
              position: 'relative', height: '100%',
              display: 'flex', alignItems: 'flex-end', justifyContent: 'center',
            }}>
              <div style={{
                position: 'absolute', left: 0, right: 0, bottom: 0,
                height: 1, background: 'var(--line-normal-neutral)',
              }}/>
              {isToday && hasValue && (
                <div style={{
                  position: 'absolute',
                  bottom: `calc(${heightPct}% + 6px)`,
                  fontSize: 10.5, fontWeight: 700,
                  color: 'var(--primary-normal)',
                  letterSpacing: '0.02em',
                  fontVariantNumeric: 'tabular-nums', whiteSpace: 'nowrap',
                }}>{Math.round(v * 100)}%</div>
              )}
              {hasValue ? (
                <div style={{
                  width: 18, height: `${heightPct}%`,
                  background: isToday ? 'var(--primary-normal)' : 'rgba(0,102,255,0.32)',
                  borderRadius: 4,
                  transition: 'height 200ms var(--ease-standard)',
                }}/>
              ) : (
                <div style={{
                  width: 18, height: 4,
                  background: 'var(--fill-alternative)',
                  borderRadius: 4,
                }}/>
              )}
            </div>
          );
        })}
      </div>
      <div style={{
        marginTop: 10,
        display: 'grid', gridTemplateColumns: 'repeat(7, 1fr)', gap: 6,
      }}>
        {days.map((d, i) => (
          <div key={i} style={{
            textAlign: 'center',
            fontSize: 11, fontWeight: d.isToday ? 700 : 500,
            color: d.isToday ? 'var(--label-strong)' : 'var(--label-alternative)',
            letterSpacing: '0.04em',
          }}>{d.label}</div>
        ))}
      </div>
    </div>
  );
}

function TodayGrid({ items, onToggle }) {
  return (
    <div style={{
      display: 'grid',
      gridTemplateColumns: `repeat(${items.length}, 1fr)`,
      gap: 8,
    }}>
      {items.map((it) => (
        <button key={it.id} onClick={() => onToggle(it.id)} style={{
          padding: 0, border: 'none', background: 'transparent',
          cursor: 'pointer', fontFamily: 'inherit',
        }}>
          <div style={{
            width: '100%', aspectRatio: '1 / 1', borderRadius: 8,
            background: it.taken ? 'var(--primary-normal)' : '#fff',
            border: it.taken ? 'none' : '1.5px solid var(--line-normal-normal)',
            boxShadow: it.taken ? '0 2px 6px rgba(0,102,255,0.18)' : 'none',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            transition: 'all 150ms',
          }}>
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none"
              stroke={it.taken ? '#fff' : 'var(--label-alternative)'}
              strokeWidth="1.7" strokeLinecap="round" strokeLinejoin="round">
              {it.kind === 'med' ? (
                <g>
                  <rect x="3" y="9" width="18" height="6" rx="3" transform="rotate(-30 12 12)"/>
                  <path d="M8.6 7.4l4.2 7.3"/>
                </g>
              ) : (
                <g>
                  <path d="M6 3v8a3 3 0 0 0 3 3v7"/>
                  <path d="M9 3v6"/>
                  <path d="M15 3c-1.5 0-3 1.5-3 4s1.5 4 3 4h.5V21H18V3z"/>
                </g>
              )}
            </svg>
          </div>
        </button>
      ))}
    </div>
  );
}

function ScheduleRow({ item, onToggle, first }) {
  const taken = item.taken;
  return (
    <button onClick={onToggle} style={{
      width: '100%', display: 'flex', alignItems: 'center', gap: 14,
      padding: '11px 18px',
      border: 'none',
      borderTop: first ? 'none' : '1px solid var(--line-normal-neutral)',
      background: 'transparent',
      cursor: 'pointer', textAlign: 'left',
      fontFamily: 'inherit', transition: 'background 180ms',
    }}>
      {/* checkbox */}
      <div style={{
        width: 22, height: 22, borderRadius: 999,
        flexShrink: 0,
        background: taken ? 'var(--primary-normal)' : 'transparent',
        border: taken ? 'none' : '1.5px solid var(--line-normal-normal)',
        boxSizing: 'border-box',
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        transition: 'all 150ms',
      }}>
        {taken && (
          <svg width="12" height="12" viewBox="0 0 24 24" fill="none"
            stroke="#fff" strokeWidth="3" strokeLinecap="round" strokeLinejoin="round">
            <path d="M5 12.5l4.5 4.5L20 7"/>
          </svg>
        )}
      </div>
      {/* name + time stacked */}
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{
          fontSize: 14.5, fontWeight: 500,
          color: taken ? 'var(--label-alternative)' : 'var(--label-strong)',
          letterSpacing: '-0.005em',
          textDecoration: taken ? 'line-through' : 'none',
          textDecorationColor: 'rgba(55,56,60,0.32)',
          textDecorationThickness: '1px',
          whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis',
        }}>{item.name}</div>
        <div style={{
          marginTop: 2,
          fontSize: 11.5, fontWeight: 500,
          color: 'var(--label-alternative)',
          letterSpacing: '0.005em',
          fontVariantNumeric: 'tabular-nums',
          display: 'flex', alignItems: 'baseline', gap: 5,
        }}>
          <span>{item.time}</span>
          {taken && item.takenAt && (
            <React.Fragment>
              <span style={{ fontSize: 10 }}>→</span>
              <span style={{
                color: 'var(--primary-normal)', fontWeight: 600,
              }}>{item.takenAt}</span>
            </React.Fragment>
          )}
        </div>
      </div>
    </button>
  );
}

Object.assign(window, { HomeScreen });

// ─── TodayRing — 24시 링 (오늘 복용 시각) ──────────────────────────
function TodayRing({ items }) {
  const NOW = '16:30';
  const T = (s) => { const [h, m] = s.split(':').map(Number); return h * 60 + m; };
  const NOW_MIN = T(NOW);
  const meds = items.filter(i => i.kind === 'med');

  const SIZE = 220, R = 88;
  const CX = SIZE / 2, CY = SIZE / 2;
  const angleOfMin = (m) => (m / (24 * 60)) * 360 - 90;
  const polar = (m, r) => {
    const a = angleOfMin(m) * Math.PI / 180;
    return { x: CX + Math.cos(a) * r, y: CY + Math.sin(a) * r };
  };
  const arcPath = (m0, m1, r) => {
    const a0 = polar(m0, r), a1 = polar(m1, r);
    const sweep = ((m1 - m0) / (24 * 60)) * 360;
    const large = sweep > 180 ? 1 : 0;
    return `M ${a0.x} ${a0.y} A ${r} ${r} 0 ${large} 1 ${a1.x} ${a1.y}`;
  };

  return (
    <div style={{ position: 'relative', width: SIZE, height: SIZE, margin: '4px auto 0' }}>
      <svg width={SIZE} height={SIZE} viewBox={`0 0 ${SIZE} ${SIZE}`}>
        {/* track */}
        <circle cx={CX} cy={CY} r={R} fill="none"
          stroke="var(--fill-alternative)" strokeWidth={8}/>
        {/* progress arc 00 → now */}
        <path d={arcPath(0.01, NOW_MIN, R)} fill="none"
          stroke="rgba(0,102,255,0.20)" strokeWidth={8} strokeLinecap="round"/>
        {/* hour ticks (every 3h) */}
        {[0, 3, 6, 9, 12, 15, 18, 21].map(h => {
          const p1 = polar(h * 60, R + 6);
          const p2 = polar(h * 60, R + 11);
          return (
            <line key={h} x1={p1.x} y1={p1.y} x2={p2.x} y2={p2.y}
              stroke="var(--line-normal-normal)" strokeWidth={1}/>
          );
        })}
        {/* now indicator */}
        {(() => {
          const p = polar(NOW_MIN, R);
          return <circle cx={p.x} cy={p.y} r={4.5} fill="var(--label-strong)"/>;
        })()}
        {/* med markers */}
        {meds.map(m => {
          const isTaken = m.taken;
          const sched = T(m.time);
          const isOverdue = !isTaken && sched < NOW_MIN;
          const tm = isTaken && m.takenAt ? T(m.takenAt) : sched;
          const pos = polar(tm, R);
          return (
            <circle key={m.id} cx={pos.x} cy={pos.y} r={12}
              fill={isTaken ? 'var(--primary-normal)' : '#fff'}
              stroke={isTaken ? 'none'
                : isOverdue ? 'var(--status-cautionary)' : 'var(--line-normal-normal)'}
              strokeWidth={2}/>
          );
        })}
      </svg>

      {/* pill icons over markers */}
      {meds.map(m => {
        const isTaken = m.taken;
        const sched = T(m.time);
        const isOverdue = !isTaken && sched < NOW_MIN;
        const tm = isTaken && m.takenAt ? T(m.takenAt) : sched;
        const pos = polar(tm, R);
        return (
          <div key={m.id} style={{
            position: 'absolute', left: pos.x, top: pos.y,
            transform: 'translate(-50%, -50%)', pointerEvents: 'none',
          }}>
            <svg width="11" height="11" viewBox="0 0 24 24" fill="none"
              stroke={isTaken ? '#fff'
                : isOverdue ? 'var(--status-cautionary)' : 'var(--label-alternative)'}
              strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
              <rect x="3" y="9" width="18" height="6" rx="3" transform="rotate(-30 12 12)"/>
              <path d="M8.6 7.4l4.2 7.3"/>
            </svg>
          </div>
        );
      })}

      {/* center label */}
      <div style={{
        position: 'absolute', inset: 0,
        display: 'flex', flexDirection: 'column',
        alignItems: 'center', justifyContent: 'center',
        textAlign: 'center', pointerEvents: 'none',
      }}>
        <div style={{
          fontSize: 9.5, fontWeight: 700, letterSpacing: '0.1em',
          color: 'var(--label-neutral)', textTransform: 'uppercase',
        }}>지금</div>
        <div style={{
          marginTop: 2,
          fontFamily: 'var(--font-display)',
          fontSize: 26, fontWeight: 700,
          color: 'var(--label-strong)',
          letterSpacing: '-0.02em',
          fontVariantNumeric: 'tabular-nums', lineHeight: 1,
        }}>{NOW}</div>
      </div>

      {/* outer hour labels — 사분면 별 정렬 */}
      {[
        { h: 0,  transform: 'translate(-50%, -100%)' }, // 위
        { h: 6,  transform: 'translate(0, -50%)' },     // 오른쪽
        { h: 12, transform: 'translate(-50%, 0)' },     // 아래
        { h: 18, transform: 'translate(-100%, -50%)' }, // 왼쪽
      ].map(({ h, transform }) => {
        const p = polar(h * 60, R + 6);
        return (
          <div key={h} style={{
            position: 'absolute', left: p.x, top: p.y,
            transform,
            fontSize: 10, fontWeight: 600,
            color: 'var(--label-alternative)',
            fontVariantNumeric: 'tabular-nums', letterSpacing: '0.02em',
            whiteSpace: 'nowrap',
            padding: '0 3px',
          }}>{h}시</div>
        );
      })}
    </div>
  );
}

Object.assign(window, { TodayRing });
