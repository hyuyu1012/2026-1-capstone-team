// ─── Records screen ───────────────────────────────────────────────
function RecordsScreen() {
  const [selectedDate, setSelectedDate] = React.useState(TODAY);
  const day = generateDay(selectedDate);
  const doneCount = day.filter(d => d.taken).length;
  const totalCount = day.length;
  const dayOfWeek = WEEK_LABELS[(FIRST_OFFSET + selectedDate - 1) % 7];

  return (
    <div style={{ padding: '4px 24px 32px' }}>
      <PageHeader
        title="복용 기록을 확인하세요"
        subtitle={`${PATIENT.relation} · ${PATIENT.name}`}
      />

      {/* 달력 카드 */}
      <div style={{
        marginTop: 24, padding: '18px 16px',
        border: '1px solid var(--line-normal-neutral)',
        borderRadius: 16, background: '#fff',
      }}>
        <div style={{
          display: 'flex', alignItems: 'center', justifyContent: 'space-between',
          padding: '0 4px 14px',
        }}>
          <button aria-label="이전 달" style={{
            width: 28, height: 28, border: 'none', background: 'transparent',
            cursor: 'pointer', color: 'var(--label-neutral)',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            borderRadius: 999, padding: 0,
          }}>
            <ChevronLeft />
          </button>
          <span style={{
            fontSize: 14, fontWeight: 700, letterSpacing: '-0.005em',
            color: 'var(--label-strong)', fontVariantNumeric: 'tabular-nums',
          }}>{MONTH_LABEL}</span>
          <button aria-label="다음 달" style={{
            width: 28, height: 28, border: 'none', background: 'transparent',
            cursor: 'pointer', color: 'var(--label-alternative)',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            borderRadius: 999, padding: 0,
          }}>
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor"
              strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
              <path d="M9 6l6 6-6 6"/>
            </svg>
          </button>
        </div>

        <div style={{
          display: 'grid', gridTemplateColumns: 'repeat(7, 1fr)',
          gap: 4, marginBottom: 8,
        }}>
          {WEEK_LABELS.map((d, i) => (
            <div key={i} style={{
              textAlign: 'center', fontSize: 10.5, fontWeight: 700,
              color: i === 0 ? 'var(--status-cautionary)' : 'var(--label-alternative)',
              letterSpacing: '0.04em',
            }}>{d}</div>
          ))}
        </div>

        <CalendarGrid selectedDate={selectedDate} onSelect={setSelectedDate} />

        <div style={{
          marginTop: 14, padding: '12px 4px 0',
          borderTop: '1px solid var(--line-normal-neutral)',
          display: 'flex', alignItems: 'center', gap: 6,
          fontSize: 10.5, fontWeight: 600, color: 'var(--label-alternative)',
          letterSpacing: '0.02em',
        }}>
          <span>적음</span>
          {[0, 0.33, 0.66, 1].map((v, i) => <LegendDot key={i} value={v} />)}
          <span>많음</span>
        </div>
      </div>

      <div style={{ marginTop: 28 }}>
        <div style={{
          display: 'flex', alignItems: 'baseline', justifyContent: 'space-between',
          marginBottom: 10, padding: '0 4px',
        }}>
          <span style={{
            fontSize: 14, fontWeight: 700,
            color: 'var(--label-strong)',
            letterSpacing: '-0.005em',
            fontVariantNumeric: 'tabular-nums',
          }}>
            5월 {selectedDate}일 {dayOfWeek}요일
            {selectedDate === TODAY && (
              <span style={{
                marginLeft: 8, color: 'var(--primary-normal)',
              }}>오늘</span>
            )}
          </span>
          <span style={{
            fontSize: 14, fontWeight: 700,
            color: 'var(--label-alternative)',
            letterSpacing: '-0.005em',
            fontVariantNumeric: 'tabular-nums',
          }}>{doneCount} / {totalCount}</span>
        </div>

        <div style={{
          background: '#fff', borderRadius: 14,
          border: '1px solid var(--line-normal-neutral)',
          overflow: 'hidden',
        }}>
          {day.map((it, i) => <DayRow key={i} item={it} first={i === 0} />)}
        </div>
      </div>
    </div>
  );
}

function CalendarGrid({ selectedDate, onSelect }) {
  const cells = [];
  for (let i = 0; i < FIRST_OFFSET; i++) cells.push({ empty: true });
  for (let d = 1; d <= DAYS_IN_MONTH; d++) {
    cells.push({
      day: d, value: MONTH_DATA[d - 1],
      today: d === TODAY, future: d > TODAY,
      selected: d === selectedDate,
    });
  }
  while (cells.length % 7 !== 0) cells.push({ empty: true });
  return (
    <div style={{ display: 'grid', gridTemplateColumns: 'repeat(7, 1fr)', gap: 4 }}>
      {cells.map((c, i) => (
        c.empty ? <div key={i} />
          : <DateCell key={i} {...c} onClick={() => !c.future && onSelect(c.day)} />
      ))}
    </div>
  );
}

function DateCell({ day, value, today, future, selected, onClick }) {
  let bg = 'transparent';
  if (future || value === null || value === undefined || value === 0) bg = 'transparent';
  else if (value <= 0.34) bg = 'rgba(0,102,255,0.18)';
  else if (value <= 0.67) bg = 'rgba(0,102,255,0.40)';
  else if (value < 1) bg = 'rgba(0,102,255,0.68)';
  else bg = 'var(--primary-normal)';

  const isHighFill = value !== null && value !== undefined && value > 0.5;
  const numColor = future ? 'var(--label-alternative)'
    : isHighFill ? '#fff' : 'var(--label-strong)';

  return (
    <button onClick={onClick} disabled={future} style={{
      aspectRatio: '1 / 1',
      border: selected ? '2px solid var(--label-strong)'
        : today    ? '1.5px solid var(--label-strong)'
                   : '1.5px solid transparent',
      borderRadius: 8, background: bg,
      cursor: future ? 'default' : 'pointer',
      padding: 0,
      display: 'flex', alignItems: 'center', justifyContent: 'center',
      fontFamily: 'var(--font-sans)',
      fontSize: 13, fontWeight: today || selected ? 700 : 600,
      color: numColor,
      letterSpacing: '-0.005em',
      fontVariantNumeric: 'tabular-nums',
      transition: 'all 150ms',
    }}>{day}</button>
  );
}

function LegendDot({ value }) {
  let bg;
  if (value === 0) bg = 'var(--fill-alternative)';
  else if (value <= 0.34) bg = 'rgba(0,102,255,0.18)';
  else if (value <= 0.67) bg = 'rgba(0,102,255,0.40)';
  else if (value < 1)     bg = 'rgba(0,102,255,0.68)';
  else                    bg = 'var(--primary-normal)';
  return <div style={{ width: 10, height: 10, borderRadius: 3, background: bg }}/>;
}

function DayRow({ item, first }) {
  const taken = item.taken;
  return (
    <div style={{
      width: '100%', display: 'flex', alignItems: 'center', gap: 14,
      padding: '11px 18px',
      borderTop: first ? 'none' : '1px solid var(--line-normal-neutral)',
      fontFamily: 'inherit',
    }}>
      {/* checkbox */}
      <div style={{
        width: 22, height: 22, borderRadius: 999,
        flexShrink: 0,
        background: taken ? 'var(--primary-normal)' : 'transparent',
        border: taken ? 'none'
          : '1.5px solid var(--c-red-60)',
        boxSizing: 'border-box',
        display: 'flex', alignItems: 'center', justifyContent: 'center',
      }}>
        {taken ? (
          <svg width="12" height="12" viewBox="0 0 24 24" fill="none"
            stroke="#fff" strokeWidth="3" strokeLinecap="round" strokeLinejoin="round">
            <path d="M5 12.5l4.5 4.5L20 7"/>
          </svg>
        ) : (
          <svg width="10" height="10" viewBox="0 0 24 24" fill="none"
            stroke="var(--c-red-60)" strokeWidth="3" strokeLinecap="round" strokeLinejoin="round">
            <path d="M6 6l12 12M18 6L6 18"/>
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
    </div>
  );
}

Object.assign(window, { RecordsScreen });
