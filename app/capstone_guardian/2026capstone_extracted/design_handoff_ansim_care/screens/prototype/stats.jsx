// ─── Stats screen — 미니멀: 주간 막대 + 월간 면적 그래프 ──────────
function StatsScreen() {
  // 이번 주: MONTH_DATA[24..30] (5월 25 월요일 ~ 5월 31 일요일)
  const WEEK = [
    { label: '월', date: 25, value: MONTH_DATA[24] },
    { label: '화', date: 26, value: MONTH_DATA[25] },
    { label: '수', date: 27, value: MONTH_DATA[26], isToday: true },
    { label: '목', date: 28, value: MONTH_DATA[27] },
    { label: '금', date: 29, value: MONTH_DATA[28] },
    { label: '토', date: 30, value: MONTH_DATA[29] },
    { label: '일', date: 31, value: MONTH_DATA[30] },
  ];
  const weekVals = WEEK.map(d => d.value).filter(v => v !== null && v !== undefined);
  const weekAvg = weekVals.length ? weekVals.reduce((a,b)=>a+b,0) / weekVals.length : 0;

  // 이번 달: MONTH_DATA — 미래는 null
  const monthVals = MONTH_DATA.filter(v => v !== null && v !== undefined);
  const monthAvg = monthVals.length ? monthVals.reduce((a,b)=>a+b,0) / monthVals.length : 0;

  return (
    <div style={{ padding: '4px 24px 32px' }}>
      <PageHeader
        title="복용 패턴을 살펴보세요"
        subtitle={`${PATIENT.relation} · ${PATIENT.name}`}
      />

      {/* 이번 주 — 막대 그래프 */}
      <div style={{
        marginTop: 24, padding: '20px 18px',
        border: '1px solid var(--line-normal-neutral)',
        borderRadius: 16, background: '#fff',
      }}>
        <div style={{
          display: 'flex', alignItems: 'baseline', justifyContent: 'space-between',
          marginBottom: 18,
        }}>
          <span style={{
            fontSize: 11.5, fontWeight: 700, letterSpacing: '0.1em',
            color: 'var(--label-neutral)', textTransform: 'uppercase',
          }}>이번 주</span>
          <span style={{
            fontSize: 12.5, fontWeight: 700, letterSpacing: '-0.005em',
            color: 'var(--label-strong)',
            fontVariantNumeric: 'tabular-nums',
          }}>주평균 {Math.round(weekAvg * 100)}%</span>
        </div>
        <WeeklyBarsStats week={WEEK} />
      </div>

      {/* 이번 달 — 면 그래프 */}
      <div style={{
        marginTop: 20, padding: '20px 18px',
        border: '1px solid var(--line-normal-neutral)',
        borderRadius: 16, background: '#fff',
      }}>
        <div style={{
          display: 'flex', alignItems: 'baseline', justifyContent: 'space-between',
          marginBottom: 18,
        }}>
          <span style={{
            fontSize: 11.5, fontWeight: 700, letterSpacing: '0.1em',
            color: 'var(--label-neutral)', textTransform: 'uppercase',
          }}>이번 달</span>
          <span style={{
            fontSize: 12.5, fontWeight: 700, letterSpacing: '-0.005em',
            color: 'var(--label-strong)',
            fontVariantNumeric: 'tabular-nums',
          }}>월평균 {Math.round(monthAvg * 100)}%</span>
        </div>
        <MonthlyArea data={MONTH_DATA} today={TODAY} />
      </div>

      {/* 자주 누락한 항목 */}
      <div style={{ marginTop: 20 }}>
        <div style={{
          padding: '0 4px 10px',
          fontSize: 11.5, fontWeight: 700, letterSpacing: '0.1em',
          color: 'var(--label-neutral)', textTransform: 'uppercase',
        }}>자주 누락한 항목</div>
        <div style={{
          background: '#fff', borderRadius: 14,
          border: '1px solid var(--line-normal-neutral)',
          overflow: 'hidden',
        }}>
          {MissedItems()}
        </div>
      </div>
    </div>
  );
}

// ─── 누락 항목 리스트 ────────────────────────────────────────────
function MissedItems() {
  // 가짜 누락 데이터 (이번 달, 27일 기준)
  const items = [
    { name: '아토르바스타틴 10mg', time: '20:00', missed: 6, total: 27 },
    { name: '저녁 식사',           time: '18:30', missed: 4, total: 27 },
    { name: '점심 식사',           time: '12:30', missed: 3, total: 27 },
    { name: '메트포르민 500mg',    time: '12:30', missed: 2, total: 27 },
  ];
  const maxMissed = Math.max(...items.map(i => i.missed));

  return items.map((it, i) => {
    const widthPct = (it.missed / maxMissed) * 100;
    return (
      <div key={i} style={{
        padding: '12px 18px',
        borderTop: i === 0 ? 'none' : '1px solid var(--line-normal-neutral)',
      }}>
        <div style={{
          display: 'flex', alignItems: 'baseline', justifyContent: 'space-between',
          marginBottom: 6,
        }}>
          <div style={{ flex: 1, minWidth: 0 }}>
            <span style={{
              fontSize: 13.5, fontWeight: 600,
              color: 'var(--label-strong)',
              letterSpacing: '-0.005em',
            }}>{it.name}</span>
            <span style={{
              marginLeft: 8, fontSize: 11, fontWeight: 500,
              color: 'var(--label-neutral)',
              fontVariantNumeric: 'tabular-nums',
              letterSpacing: '0.02em',
            }}>{it.time}</span>
          </div>
          <span style={{
            fontSize: 12.5, fontWeight: 700,
            color: 'var(--c-red-60)',
            fontVariantNumeric: 'tabular-nums',
            letterSpacing: '-0.005em',
            flexShrink: 0,
          }}>{it.missed}<span style={{
            fontSize: 11, fontWeight: 500, color: 'var(--label-alternative)',
          }}> / {it.total}일</span></span>
        </div>
        <div style={{
          height: 4, borderRadius: 999,
          background: 'var(--fill-alternative)',
          overflow: 'hidden',
        }}>
          <div style={{
            width: `${widthPct}%`, height: '100%',
            background: 'var(--c-red-60)',
            borderRadius: 999,
          }}/>
        </div>
      </div>
    );
  });
}

// ─── 주간 막대 (Home v7과 같은 스타일, 단색) ──────────────────────
function WeeklyBarsStats({ week }) {
  const H = 130;
  return (
    <div>
      <div style={{
        display: 'grid', gridTemplateColumns: 'repeat(7, 1fr)',
        gap: 6, height: H, alignItems: 'end',
      }}>
        {week.map((d, i) => {
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
        {week.map((d, i) => (
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

// ─── 월간 면 그래프 (SVG) ──────────────────────────────────────────
function MonthlyArea({ data, today }) {
  const W = 312, H = 150;
  const PAD_L = 0, PAD_R = 0, PAD_T = 8, PAD_B = 20;
  const chartW = W - PAD_L - PAD_R;
  const chartH = H - PAD_T - PAD_B;

  // x: 1..31 → 0..chartW
  const N = data.length;
  const xOf = (i) => PAD_L + (i / (N - 1)) * chartW;
  const yOf = (v) => PAD_T + (1 - v) * chartH;

  // 데이터가 있는 지점까지만 line/area
  const points = data
    .map((v, i) => ({ i, v }))
    .filter(p => p.v !== null && p.v !== undefined);

  if (points.length === 0) return <div style={{ height: H }}/>;

  // path build (line + area)
  let linePath = `M ${xOf(points[0].i)} ${yOf(points[0].v)}`;
  for (let k = 1; k < points.length; k++) {
    linePath += ` L ${xOf(points[k].i)} ${yOf(points[k].v)}`;
  }
  const areaPath = linePath
    + ` L ${xOf(points[points.length - 1].i)} ${PAD_T + chartH}`
    + ` L ${xOf(points[0].i)} ${PAD_T + chartH} Z`;

  // 가로 grid: 0, 50, 100 라인
  const grids = [0, 0.5, 1];

  // x 라벨: 1, 8, 15, 22, 27(오늘), 31
  const xTicks = [1, 8, 15, 22, today, 31];
  const uniqueTicks = [...new Set(xTicks)].sort((a, b) => a - b);

  const todayIdx = today - 1;
  const todayVal = data[todayIdx];
  const hasToday = todayVal !== null && todayVal !== undefined;

  return (
    <div>
      <svg width="100%" height={H} viewBox={`0 0 ${W} ${H}`} preserveAspectRatio="none"
        style={{ display: 'block', overflow: 'visible' }}>
        <defs>
          <linearGradient id="monthAreaGrad" x1="0" y1="0" x2="0" y2="1">
            <stop offset="0%"  stopColor="rgba(0,102,255,0.28)"/>
            <stop offset="100%" stopColor="rgba(0,102,255,0.02)"/>
          </linearGradient>
        </defs>

        {/* horizontal grids */}
        {grids.map((g, i) => (
          <line key={i}
            x1={0} x2={W}
            y1={yOf(g)} y2={yOf(g)}
            stroke="var(--line-normal-neutral)"
            strokeWidth={1}
            strokeDasharray={g === 0 ? '0' : '3 3'}
          />
        ))}

        {/* area fill */}
        <path d={areaPath} fill="url(#monthAreaGrad)" stroke="none"/>
        {/* line */}
        <path d={linePath} fill="none"
          stroke="var(--primary-normal)" strokeWidth={2}
          strokeLinejoin="round" strokeLinecap="round"/>

        {/* today marker */}
        {hasToday && (
          <g>
            <line x1={xOf(todayIdx)} x2={xOf(todayIdx)}
              y1={yOf(todayVal)} y2={PAD_T + chartH}
              stroke="var(--label-strong)" strokeWidth={1} strokeDasharray="2 3"/>
            <circle cx={xOf(todayIdx)} cy={yOf(todayVal)} r={5}
              fill="#fff" stroke="var(--label-strong)" strokeWidth={2}/>
          </g>
        )}

        {/* x labels */}
        {uniqueTicks.map((d, i) => {
          const isToday = d === today;
          return (
            <text key={i}
              x={xOf(d - 1)}
              y={H - 6}
              textAnchor="middle"
              fontSize={10}
              fontWeight={isToday ? 700 : 500}
              fill={isToday ? 'var(--label-strong)' : 'var(--label-alternative)'}
              style={{
                fontVariantNumeric: 'tabular-nums',
                letterSpacing: '0.02em',
              }}>{d}일</text>
          );
        })}

        {/* y labels (right side, 0/50/100) */}
        {grids.map((g, i) => (
          <text key={i}
            x={W - 2} y={yOf(g) - 4}
            textAnchor="end"
            fontSize={9} fontWeight={500}
            fill="var(--label-alternative)"
            style={{ fontVariantNumeric: 'tabular-nums', letterSpacing: '0.02em' }}>
            {Math.round(g * 100)}%
          </text>
        ))}
      </svg>
    </div>
  );
}

Object.assign(window, { StatsScreen });
