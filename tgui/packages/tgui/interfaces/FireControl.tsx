import { useBackend } from '../backend';
import { Box, Button, ProgressBar, Section, Stack, Table, Icon } from '../components';
import { Window } from '../layouts';

interface WeaponData {
  ref: string; name: string; type: string; state: string;
  accuracy: number; charge: number; maxCharge: number;
  rechargeTime: number; maxRechargeTime: number; damaged: boolean;
  canFire: boolean; optimalRange: number; maxRange: number;
}
interface TargetData {
  ref: string; name: string; lockStatus: string; lockProgress: number;
  distance: number; speed: number; heading: string; x: number; y: number;
}
interface AvailableTarget {
  ref: string; name: string; known: boolean; distance: number;
  type: string; x: number; y: number;
}
interface MapObject {
  ref: string; x: number; y: number; name: string; type: string;
}
interface ProjectileData {
  ref: string; weapon: string; target: string;
  flightProgress: number; timeRemaining: number; hitChance: number;
}
interface FireControlData {
  active: boolean; shipName: string; shipX: number; shipY: number;
  tacticalRange: number; sensorRange: number;
  target: TargetData | null; selectedTarget: TargetData | null;
  availableTargets: AvailableTarget[]; mapObjects: MapObject[];
  weapons: WeaponData[]; activeProjectiles: ProjectileData[];
}

const WS: Record<string, string> = { ready:'Готово', charging:'Зарядка', firing:'Огонь', damaged:'Повреждено' };
const WT: Record<string, string> = { laser:'Лазер', kinetic:'Кинет.', missile:'Ракета', energy:'Энерг.' };

export const FireControl = (_p: any, ctx: any) => {
  const { data } = useBackend<FireControlData>(ctx);
  if (!data.active) {
    return (
      <Window width={800} height={600}>
        <Window.Content>
          <Section title="Консоль управления огнем">
            <Box color="bad" textAlign="center">Система боя неактивна</Box>
          </Section>
        </Window.Content>
      </Window>
    );
  }
  return (
    <Window width={1100} height={740}>
      <Window.Content>
        <Box position="fixed" top={0} left={0} right={0} bottom={0} backgroundColor="#0a0e14" zIndex={-1} />
        <Stack vertical fill>
          {/* Середина: радар + оружие */}
          <Stack.Item grow>
            <Stack fill>
              <Stack.Item width="430px"><RadarPanel /></Stack.Item>
              <Stack.Item grow><WeaponsPanel /></Stack.Item>
            </Stack>
          </Stack.Item>
          {/* Низ: цель + снаряды + доступные цели */}
          <Stack.Item>
            <Stack fill>
              <Stack.Item grow><TargetInfoBlock /></Stack.Item>
              <Stack.Item grow><ProjectilesBlock /></Stack.Item>
            </Stack>
          </Stack.Item>
          <Stack.Item><AvailableTargetsTable /></Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};

/* ── Тактическая карта ───────────────────────────────── */
const RadarPanel = (_p: any, ctx: any) => {
  const { data } = useBackend<FireControlData>(ctx);
  const target = data.target;
  const RANGE = data.tacticalRange || 45;
  const W = 400;
  const H = 400;
  const PAD = 24;
  const cx = W / 2;
  const cy = H / 2;
  const rMax = W / 2 - PAD;
  const scale = rMax / RANGE;
  const RINGS = [0.25, 0.5, 0.75, 1.0];

  // Цель — абсолютные координаты, нужен wrap-around
  const rawDx = (target?.x ?? 0) - data.shipX;
  const rawDy = (target?.y ?? 0) - data.shipY;
  const halfMap = RANGE * 2; // приблизительно половина карты
  let dx = rawDx;
  let dy = rawDy;
  if (rawDx > halfMap) dx = rawDx - halfMap * 2;
  else if (rawDx < -halfMap) dx = rawDx + halfMap * 2;
  if (rawDy > halfMap) dy = rawDy - halfMap * 2;
  else if (rawDy < -halfMap) dy = rawDy + halfMap * 2;

  const tx = cx + dx * scale;
  const ty = cy - dy * scale;
  const lineLen = Math.hypot(tx - cx, ty - cy);
  const lineAng = Math.atan2(ty - cy, tx - cx);

  const proj = (dx: number, dy: number): [number, number] => [
    cx + dx * scale,
    cy - dy * scale,
  ];

  const mvis = (type: string) => {
    switch (type) {
      case 'star':     return { c: '#ffdd55', s: 8, cr: true };
      case 'outpost':  return { c: '#6ce26c', s: 7 };
      case 'jump':     return { c: '#c86cff', s: 7, d: true };
      case 'ship':     return { c: '#9aa0c9', s: 8 };
      case 'npc_ship': return { c: '#5f6473', s: 7 };
      case 'event':    return { c: '#ff5c5c', s: 7, ring: true };
      default:         return { c: '#5cd8ff', s: 5, cr: true };
    }
  };

  const hasT = !!target && target.lockStatus !== 'lost';
  const isAcq = hasT && target.lockStatus === 'acquiring';
  const DOT = 18;
  const objs = data.mapObjects || [];
  const projs = data.activeProjectiles || [];

  return (
    <Section title="Тактическая схема" mb={0}>
      <Box position="relative" width={`${W}px`} height={`${H}px`}
        backgroundColor="#061228"
        style={{ border: '1px solid #1a3050', overflow: 'hidden' }}>

        {RINGS.map(f => {
          const r = rMax * f;
          return (
            <Box key={f} position="absolute"
              style={{
                left: `${cx - r}px`, top: `${cy - r}px`,
                width: `${r * 2}px`, height: `${r * 2}px`,
                borderRadius: '50%',
                border: f === 1 ? '1px solid rgba(255,255,255,0.18)' : '1px dashed rgba(255,255,255,0.08)',
              }} />
          );
        })}

        <Box position="absolute"
          style={{ left: `${cx}px`, top: 0, width: '1px', height: `${H}px`, backgroundColor: 'rgba(255,255,255,0.04)' }} />
        <Box position="absolute"
          style={{ left: 0, top: `${cy}px`, width: `${W}px`, height: '1px', backgroundColor: 'rgba(255,255,255,0.04)' }} />

        {RINGS.map(f => {
          const r = rMax * f;
          return (
            <Box key={`l${f}`} position="absolute" fontSize="8px" color="rgba(255,255,255,0.25)"
              style={{ left: `${cx + 3}px`, top: `${cy - r - 8}px` }}>
              {Math.round(RANGE * f)}
            </Box>
          );
        })}

        {objs.map(obj => {
          const [mx, my] = proj(obj.x, obj.y);
          const m = mvis(obj.type);
          const half = m.s / 2;
          if (m.ring) {
            return (
              <Box key={obj.ref} tooltip={obj.name} position="absolute"
                style={{
                  left: `${mx - half}px`, top: `${my - half}px`,
                  width: `${m.s}px`, height: `${m.s}px`,
                  borderRadius: '50%', border: `2px solid ${m.c}`, opacity: 0.85,
                }} />
            );
          }
          return (
            <Box key={obj.ref} tooltip={obj.name} position="absolute"
              style={{
                left: `${mx - half}px`, top: `${my - half}px`,
                width: `${m.s}px`, height: `${m.s}px`,
                borderRadius: m.cr ? '50%' : '0',
                backgroundColor: m.c,
                transform: m.d ? 'rotate(45deg)' : undefined,
                boxShadow: `0 0 3px ${m.c}`, opacity: 0.85,
              }} />
          );
        })}

        <Box position="absolute"
          style={{
            left: `${cx - DOT / 2}px`, top: `${cy - DOT / 2}px`,
            width: `${DOT}px`, height: `${DOT}px`, borderRadius: '50%',
            border: '2px solid #5cb8ff', backgroundColor: 'rgba(40,90,150,0.6)',
            boxShadow: '0 0 6px rgba(92,184,255,0.3)',
          }} />

        {!hasT && (
          <Box position="absolute" color="label" fontSize="11px"
            style={{ left: `${cx}px`, top: `${cy + DOT}px`, width: '1px', textAlign: 'center', whiteSpace: 'nowrap', transform: 'translateX(-50%)' }}>
            Нет захвата
          </Box>
        )}

        {hasT && (
          <>
            <Box position="absolute"
              style={{
                left: `${cx}px`, top: `${cy}px`,
                width: '2px', height: `${lineLen}px`,
                transform: `rotate(${lineAng}rad)`, transformOrigin: 'top left',
                backgroundColor: 'rgba(120,170,255,0.25)',
              }} />
            <Box position="absolute"
              style={{
                left: `${tx - DOT / 2}px`, top: `${ty - DOT / 2}px`,
                width: `${DOT}px`, height: `${DOT}px`, borderRadius: '50%',
                border: `2px solid ${isAcq ? '#ffce5c' : '#ff5c5c'}`,
                backgroundColor: isAcq ? 'rgba(150,110,40,0.5)' : 'rgba(150,40,40,0.5)',
                boxShadow: `0 0 6px ${isAcq ? 'rgba(255,206,92,0.4)' : 'rgba(255,92,92,0.4)'}`,
              }} />
            <Box position="absolute" fontSize="9px" color={isAcq ? '#ffce5c' : '#ff5c5c'}
              style={{ left: `${tx - 55}px`, top: `${ty - DOT / 2 - 14}px`, width: '110px', textAlign: 'center' }}>
              {target.name}
            </Box>
            {lineLen > 30 && (
              <Box position="absolute" fontSize="8px" color="rgba(200,220,255,0.35)"
                style={{ left: `${cx + (tx - cx) / 2 - 18}px`, top: `${cy + (ty - cy) / 2 - 5}px`, width: '36px', textAlign: 'center' }}>
                {target.distance.toFixed(1)}
              </Box>
            )}
            {projs.map(p => {
              const frac = Math.max(0, Math.min(1.4, p.flightProgress / 100));
              const mx = cx + (tx - cx) * frac;
              const my = cy + (ty - cy) * frac;
              return (
                <Box key={p.ref} position="absolute"
                  style={{
                    left: `${mx - 3}px`, top: `${my - 3}px`,
                    width: '6px', height: '6px', transform: 'rotate(45deg)',
                    border: '1px solid #ffb04c', backgroundColor: 'rgba(255,140,40,0.85)',
                    boxShadow: '0 0 4px rgba(255,140,40,0.9)',
                  }} />
              );
            })}
          </>
        )}
      </Box>
      <Box color="#5cb8ff" fontSize="10px" mt={0.5} textAlign="center">{data.shipName}</Box>
    </Section>
  );
};

/* ── Инфо о захваченной цели (внизу) ─────────────────── */
const TargetInfoBlock = (_p: any, ctx: any) => {
  const { act, data } = useBackend<FireControlData>(ctx);
  const t = data.target?.lockStatus !== 'lost' ? data.target : data.selectedTarget;
  const locked = t?.lockStatus === 'locked';
  const acq = t?.lockStatus === 'acquiring';
  const hasLock = !!data.target && data.target.lockStatus !== 'lost';

  return (
    <Section title="Захваченная цель" mb={0}>
      {!t ? (
        <Box color="label" fontSize="12px">Цель не выбрана — выберите из списка ниже</Box>
      ) : (
        <>
          <Stack fill align="center">
            <Stack.Item grow>
              <Stack inline spacing={2} align="center">
                <Stack.Item><Box bold fontSize="13px">{t.name}</Box></Stack.Item>
                <Stack.Item>
                  {locked && <Box color="good" fontSize="12px">Захвачен</Box>}
                  {acq && <Box color="average" fontSize="12px">Захват {Math.round(t.lockProgress)}%</Box>}
                  {!locked && !acq && <Box color="label" fontSize="12px">Сканирование</Box>}
                </Stack.Item>
              </Stack>
            </Stack.Item>
            <Stack.Item>
              <Stack inline spacing={1}>
                {!hasLock && t && (
                  <Button icon="crosshairs" color="good" compact
                    onClick={() => act('lock_target', { target: t.ref })} tooltip="Захват" />
                )}
                {hasLock && (
                  <Button icon="times" color="bad" compact
                    onClick={() => act('clear_target')} tooltip="Сброс" />
                )}
              </Stack>
            </Stack.Item>
          </Stack>
          <Stack spacing={3} mt={1}>
            <Stack.Item>
              <Box color="label" fontSize="11px">Координаты</Box>
              <Box fontSize="12px" fontFamily="monospace">{t.x}, {t.y}</Box>
            </Stack.Item>
            <Stack.Item>
              <Box color="label" fontSize="11px">Расстояние</Box>
              <Box fontSize="12px">{t.distance.toFixed(1)} тайлов</Box>
            </Stack.Item>
            <Stack.Item>
              <Box color="label" fontSize="11px">Скорость</Box>
              <Box fontSize="12px">{t.speed}</Box>
            </Stack.Item>
            <Stack.Item>
              <Box color="label" fontSize="11px">Курс</Box>
              <Box fontSize="12px">{t.heading}</Box>
            </Stack.Item>
          </Stack>
          {acq && <ProgressBar value={t.lockProgress} maxValue={100} color="average" height="4px" mt={1} />}
          {locked && <Box color="good" fontSize="10px" mt={0.5}>Захват активен — оружие готово к применению</Box>}
        </>
      )}
    </Section>
  );
};

/* ── Снаряды (всегда виден, половина ширины) ─────────── */
const ProjectilesBlock = (_p: any, ctx: any) => {
  const { data } = useBackend<FireControlData>(ctx);
  const projs = data.activeProjectiles || [];

  return (
    <Section title={`Снаряды в полёте (${projs.length})`} mb={0}>
      {projs.length === 0 ? (
        <Box color="label" fontSize="11px">Нет активных снарядов</Box>
      ) : (
        <Table fontSize="11px">
          <Table.Row header>
            <Table.Cell>Оружие</Table.Cell>
            <Table.Cell>Цель</Table.Cell>
            <Table.Cell>Попадание</Table.Cell>
            <Table.Cell textAlign="right">Шанс</Table.Cell>
          </Table.Row>
          {projs.map((p: ProjectileData) => (
            <Table.Row key={p.ref}>
              <Table.Cell>{p.weapon}</Table.Cell>
              <Table.Cell>{p.target}</Table.Cell>
              <Table.Cell>
                <Box color="average" fontFamily="monospace">
                  {Math.round(p.timeRemaining / 10)}с
                </Box>
              </Table.Cell>
              <Table.Cell textAlign="right">
                <Box color={p.hitChance >= 70 ? 'good' : p.hitChance >= 40 ? 'average' : 'bad'}>
                  {p.hitChance}%
                </Box>
              </Table.Cell>
            </Table.Row>
          ))}
        </Table>
      )}
    </Section>
  );
};

/* ── Вооружение ──────────────────────────────────────── */
const WeaponsPanel = (_p: any, ctx: any) => {
  const { act, data } = useBackend<FireControlData>(ctx);
  const weapons = data.weapons || [];

  return (
    <Section title="Вооружение" scrollable fill mb={0}
      buttons={<Button icon="sync" size="small" compact onClick={() => act('refresh_weapons')} tooltip="Обновить" />}>
      {weapons.length === 0 ? (
        <Box color="average" textAlign="center">Вооружение не обнаружено</Box>
      ) : weapons.slice(0, 8).map((w: WeaponData) => {
        const canFire = w.canFire && data.target?.lockStatus === 'locked';
        const dmg = !!w.damaged;
        const clr = dmg ? '#e74c3c' : w.state === 'charging' ? '#f39c12' : w.state === 'firing' ? '#e74c3c' : '#2ecc71';
        const stateLabel = dmg ? 'Повреждено' : WS[w.state] || w.state;

        return (
          <Box key={w.ref} mb="6px"
            style={{
              borderRadius: '4px',
              border: `1px solid ${clr}33`,
              borderLeft: `4px solid ${clr}`,
              backgroundColor: 'rgba(255,255,255,0.03)',
            }}>
            {/* Верхняя часть: имя + кнопка */}
            <Stack fill align="center" p="6px" pb="4px">
              <Stack.Item grow>
                <Box fontSize="14px" bold color="white">{w.name}</Box>
                <Box fontSize="11px" mt="2px">
                  <span style={{ color: clr }}>{stateLabel}</span>
                  <span style={{ color: '#888' }}> · {WT[w.type] || w.type} · Точность {w.accuracy}%</span>
                </Box>
              </Stack.Item>
              <Stack.Item>
                {dmg ? (
                  <Button icon="wrench" color="average" fontSize="12px"
                    onClick={() => act('repair_weapon', { weapon: w.ref })} tooltip="Ремонт">
                    Ремонт
                  </Button>
                ) : (
                  <Button color={canFire ? 'good' : 'grey'} disabled={!canFire} fontSize="12px"
                    onClick={() => act('fire_weapon', { weapon: w.ref })}
                    tooltip={canFire ? 'Открыть огонь' : 'Невозможно'}>
                    Огонь!
                  </Button>
                )}
              </Stack.Item>
            </Stack>

            {/* Заряд */}
            <Box px="6px" pb="6px">
              <Stack align="center" spacing={1}>
                <Stack.Item grow>
                  <ProgressBar value={w.charge} maxValue={w.maxCharge} height="18px" color="blue">
                    <Box fontSize="11px" bold>{w.charge} / {w.maxCharge}</Box>
                  </ProgressBar>
                </Stack.Item>
                <Stack.Item>
                  <Box fontSize="11px" color="label" whiteSpace="nowrap" textAlign="right" minWidth="80px">
                    макс. {w.maxRange}т
                  </Box>
                </Stack.Item>
              </Stack>
              {w.rechargeTime > 0 && (
                <ProgressBar value={w.rechargeTime} maxValue={w.maxRechargeTime} height="6px" color="orange" mt="3px" />
              )}
            </Box>
          </Box>
        );
      })}
    </Section>
  );
};

/* ── Доступные цели ──────────────────────────────────── */
const AvailableTargetsTable = (_p: any, ctx: any) => {
  const { act, data } = useBackend<FireControlData>(ctx);
  const targets = data.availableTargets?.slice(0, 4) || [];

  return (
    <Section title="Доступные цели" compact mb={0}
      buttons={<Button icon="list" color="transparent" size="small" compact
        onClick={() => act('select_target_manual')} tooltip="Вручную" />}>
      <Table fontSize="11px">
        <Table.Row header>
          <Table.Cell width="30px" />
          <Table.Cell width="55px">Статус</Table.Cell>
          <Table.Cell width="55px">Коорд.</Table.Cell>
          <Table.Cell>Объект</Table.Cell>
          <Table.Cell width="45px" textAlign="right">Дист.</Table.Cell>
        </Table.Row>
        {targets.length === 0 ? (
          <Table.Row><Table.Cell colSpan={5} textAlign="center">
            <Box color="label">Цели не обнаружены</Box>
          </Table.Cell></Table.Row>
        ) : targets.map((t: AvailableTarget) => {
          const isCur = !!data.target && data.target.ref === t.ref;
          const lock = isCur ? data.target : null;
          const rl = lock?.lockStatus === 'locked';
          const ra = lock?.lockStatus === 'acquiring';
          return (
            <Table.Row key={t.ref}>
              <Table.Cell>
                {isCur ? (
                  <Button icon="unlink" color="bad" compact size="small"
                    onClick={() => act('clear_target')} tooltip="Снять" />
                ) : (
                  <Button icon="crosshairs" compact size="small"
                    onClick={() => act('lock_target', { target: t.ref })} tooltip="Захват" />
                )}
              </Table.Cell>
              <Table.Cell>
                {rl ? <Box color="good" fontSize="10px">Захват</Box>
                  : ra && lock ? <Box color="average" fontSize="10px">{Math.round(lock.lockProgress)}%</Box>
                  : <Box color="label" fontSize="10px">—</Box>}
              </Table.Cell>
              <Table.Cell><Box fontFamily="monospace" fontSize="10px">{t.x},{t.y}</Box></Table.Cell>
              <Table.Cell>
                <Box fontSize="11px">{t.name}</Box>
                <Box color="label" fontSize="9px">{t.type}</Box>
              </Table.Cell>
              <Table.Cell textAlign="right"><Box color="label" fontSize="10px">{t.distance.toFixed(1)}т</Box></Table.Cell>
            </Table.Row>
          );
        })}
      </Table>
    </Section>
  );
};
