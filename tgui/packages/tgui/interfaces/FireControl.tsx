import { useBackend } from '../backend';
import { Box, Button, LabeledList, ProgressBar, Section, Stack, Table, Icon } from '../components';
import { Window } from '../layouts';


interface WeaponData {
  ref: string;
  name: string;
  type: string;
  state: string;
  damage: number;
  accuracy: number;
  charge: number;
  maxCharge: number;
  rechargeTime: number;
  maxRechargeTime: number;
  damaged: boolean;
  misfireChance: number;
  canFire: boolean;
  targetDistance: number;
  inRange: boolean;
  optimalRange: number;
  maxRange: number;
}

interface TargetData {
  ref: string;
  name: string;
  lockStatus: string;
  lockProgress: number;
  distance: number;
  speed: number;
  heading: string;
  x: number;
  y: number;
}

interface AvailableTarget {
  ref: string;
  name: string;
  known: boolean;
  distance: number;
  type: string;
  speed: number;
  heading: string;
  x: number;
  y: number;
  brg: number;
  cpa: number;
}

interface MapObject {
  ref: string;
  x: number;
  y: number;
  name: string;
  known: boolean;
  type: string;
  icon: string;
}

interface ProjectileData {
  ref: string;
  weapon: string;
  target: string;
  flightProgress: number;
  timeRemaining: number;
  hitChance: number;
}

interface CombatStats {
  damageMultiplier: number;
  accuracyMultiplier: number;
  rechargeMultiplier: number;
}

interface FireControlData {
  active: boolean;
  scanning: boolean;
  lastScan: number;
  scanInterval: number;
  shipName: string;
  shipSpeed: number;
  shipHeading: string;
  shipX: number;
  shipY: number;
  tacticalRange: number;
  sensorRange: number;
  target: TargetData | null;
  selectedTarget: TargetData | null;
  availableTargets: AvailableTarget[];
  mapObjects: MapObject[];
  weapons: WeaponData[];
  activeProjectiles: ProjectileData[];
  combatStats: CombatStats;
}

const WeaponState = {
  ready: 'Готово',
  charging: 'Зарядка',
  firing: 'Огонь',
  damaged: 'Повреждено',
  disabled: 'Отключено',
};

const WeaponType = {
  laser: 'Лазер',
  kinetic: 'Кинетическое',
  missile: 'Ракета',
  energy: 'Энергетическое',
};

export const FireControl = (props, context) => {
  const { act, data } = useBackend<FireControlData>(context);

  if (!data.active) {
    return (
      <Window width={800} height={600}>
        <Window.Content>
          <Section title="Консоль управления огнем">
            <Box color="bad" textAlign="center">
              Система боя неактивна. Проверьте подключение к кораблю.
            </Box>
          </Section>
        </Window.Content>
      </Window>
    );
  }

  return (
    <Window width={1200} height={880}>
      <Window.Content scrollable>
        <Stack vertical fill>
          <Stack.Item>
            <Stack fill>
              <Stack.Item grow={1}>
                <ShipStatusSection />
              </Stack.Item>
              <Stack.Item grow={2}>
                <TargetSection />
              </Stack.Item>
            </Stack>
          </Stack.Item>
          <Stack.Item grow={1}>
            <Stack fill>
              <Stack.Item grow={3}>
                <TacticalMapSection />
              </Stack.Item>
              <Stack.Item grow={2}>
                <WeaponsSection />
              </Stack.Item>
            </Stack>
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};

const ShipStatusSection = (props, context) => {
  const { data } = useBackend<FireControlData>(context);

  return (
    <Section title="Статус корабля">
      <LabeledList>
        <LabeledList.Item label="Корабль">
          {data.shipName}
        </LabeledList.Item>
        <LabeledList.Item label="Скорость">
          {data.shipSpeed}
        </LabeledList.Item>
        <LabeledList.Item label="Курс">
          {data.shipHeading}
        </LabeledList.Item>
        <LabeledList.Item label="Радиус сенсоров (ARPA)">
          {data.sensorRange} тайлов
        </LabeledList.Item>
      </LabeledList>
    </Section>
  );
};

const TargetSection = (props, context) => {
  const { act, data } = useBackend<FireControlData>(context);

  const renderTargetInfo = () => {
    // Приоритет у цели в боевом захвате; иначе показываем отсканированную (выбранную)
    const effective =
      data.target && data.target.lockStatus !== 'lost' ? data.target : data.selectedTarget;

    if (!effective) {
      return (
        <Box color="average" textAlign="center">
          Цель не выбрана
        </Box>
      );
    }

    const locked = effective.lockStatus === 'locked';
    const acquiring = effective.lockStatus === 'acquiring';
    const scanOnly = !data.target || data.target.lockStatus === 'lost';
    const targetLocked = data.target?.lockStatus === 'locked';

    return (
      <>
        <LabeledList>
          <LabeledList.Item label="Цель">
            {effective.name}
          </LabeledList.Item>
          <LabeledList.Item label="Статус">
            {locked ? (
              <Box color="good">Захвачен</Box>
            ) : acquiring ? (
              <>
                <Box color="average">Захват...</Box>
                <ProgressBar value={effective.lockProgress} maxValue={100}>
                  {Math.round(effective.lockProgress)}%
                </ProgressBar>
              </>
            ) : (
              <Box color="label">Сканирование (захват не ведётся)</Box>
            )}
          </LabeledList.Item>
          <LabeledList.Item label="Координаты">
            <Box fontFamily="monospace">
              {effective.x}, {effective.y}
            </Box>
          </LabeledList.Item>
          <LabeledList.Item label="Расстояние">
            {effective.distance.toFixed(1)} тайлов
          </LabeledList.Item>
          <LabeledList.Item label="Скорость цели">
            {effective.speed}
          </LabeledList.Item>
          <LabeledList.Item label="Курс цели">
            {effective.heading}
          </LabeledList.Item>
        </LabeledList>
        {scanOnly && (
          <Button
            mt={1}
            fluid
            icon="crosshairs"
            color="good"
            onClick={() => act('lock_target', { target: effective.ref })}
          >
            Взять в захват
          </Button>
        )}
        {targetLocked && (
          <Box mt={1} color="bad" fontSize="11px">
            Внимание: захват активен — оружие готово к применению.
          </Box>
        )}
        <Button
          mt={1}
          fluid
          icon="times"
          color="bad"
          onClick={() => act('clear_target')}
        >
          Сбросить цель
        </Button>
      </>
    );
  };

  // Оптимизация: ограничиваем количество отображаемых целей
  const visibleTargets = data.availableTargets?.slice(0, 8) || [];

  const renderTargetRow = (t: AvailableTarget) => {
    const isCurrent = !!data.target && data.target.ref === t.ref;
    const lock = isCurrent ? data.target : null;
    const rowLocked = lock?.lockStatus === 'locked';
    const rowAcquiring = lock?.lockStatus === 'acquiring';

    return (
      <Table.Row key={t.ref}>
        <Table.Cell>
          {isCurrent ? (
            <Button
              icon="unlink"
              color="bad"
              onClick={() => act('clear_target')}
              tooltip={rowLocked ? 'Снять захват с цели' : 'Прервать захват цели'}
            >
              Снять
            </Button>
          ) : (
            <Button
              icon="crosshairs"
              onClick={() => act('lock_target', { target: t.ref })}
              tooltip="Взять цель в захват"
            />
          )}
        </Table.Cell>
        <Table.Cell>
          {rowLocked ? (
            <Box color="good">Захвачен</Box>
          ) : rowAcquiring && lock ? (
            <ProgressBar value={lock.lockProgress} maxValue={100} width="120px">
              Захват {Math.round(lock.lockProgress)}%
            </ProgressBar>
          ) : (
            <Box color="label">—</Box>
          )}
        </Table.Cell>
        <Table.Cell>
          <Box fontFamily="monospace">
            {t.x}, {t.y}
          </Box>
        </Table.Cell>
        <Table.Cell>
          <Stack inline align="center">
            {!t.known && (
              <Stack.Item>
                <Icon name="eye-slash" color="average" tooltip="Транспондер выключен" />
              </Stack.Item>
            )}
            <Stack.Item grow>
              <Button
                color="transparent"
                fluid
                onClick={() => act('select_target', { target: t.ref })}
                tooltip="Отсканировать корабль (без захвата)"
                style={{ padding: '0 4px', textAlign: 'left' }}
              >
                <Box>{t.name}</Box>
                <Box color="label" fontSize="10px">
                  {t.type}
                </Box>
              </Button>
            </Stack.Item>
          </Stack>
        </Table.Cell>
      </Table.Row>
    );
  };

  return (
    <Section title="Управление целью">
      <Stack fill>
        <Stack.Item grow={1}>
          {renderTargetInfo()}
        </Stack.Item>
        <Stack.Item grow={1}>
          <Section
            title="Доступные цели (ARPA)"
            scrollable
            fill
            buttons={
              <Button
                icon="list"
                color="transparent"
                onClick={() => act('select_target_manual')}
                tooltip="Выбрать цель вручную из списка кораблей"
              >
                Выбрать вручную
              </Button>
            }
          >
            <Table>
              <Table.Row header>
                <Table.Cell>Действие</Table.Cell>
                <Table.Cell>Статус</Table.Cell>
                <Table.Cell>Координаты</Table.Cell>
                <Table.Cell>Объект</Table.Cell>
              </Table.Row>
              {visibleTargets.length === 0 ? (
                <Table.Row>
                  <Table.Cell colSpan={4} textAlign="center">
                    <Box color="average">Цели не обнаружены</Box>
                  </Table.Cell>
                </Table.Row>
              ) : (
                visibleTargets.map(renderTargetRow)
              )}
              {data.availableTargets?.length > 8 && (
                <Table.Row>
                  <Table.Cell colSpan={4} textAlign="center">
                    <Box color="average" fontSize="10px">
                      Показано 8 из {data.availableTargets.length} целей
                    </Box>
                  </Table.Cell>
                </Table.Row>
              )}
            </Table>
          </Section>
        </Stack.Item>
      </Stack>
    </Section>
  );
};

const TacticalMapSection = (props, context) => {
  const { data } = useBackend<FireControlData>(context);

  const target = data.target;
  const RANGE = data.tacticalRange || 45;
  const W = 960;
  const H = 470;
  const P = 48;

  const sx = W / 2;
  const sy = H / 2;
  // Максимальный видимый радиус радара (ограничен высотой канваса и полями).
  const radarR = Math.min(W, H) / 2 - P;
  // Кольца дальности в долях от полного радиуса радара.
  const RING_FRACTIONS = [0.25, 0.5, 0.75, 1];
  const dx = (target?.x ?? data.shipX) - data.shipX;
  const dy = (target?.y ?? data.shipY) - data.shipY;

  const scaleX = (W / 2 - P) / RANGE;
  const scaleY = (H / 2 - P) / RANGE;

  const tx = Math.max(P, Math.min(W - P, sx + dx * scaleX));
  const ty = Math.max(P, Math.min(H - P, sy - dy * scaleY));

  const lineLen = Math.hypot(tx - sx, ty - sy);
  const lineAngle = Math.atan2(ty - sy, tx - sx);

  const DOT = 34;
  const projectiles = data.activeProjectiles || [];
  const mapObjects = data.mapObjects || [];

  // Проекция координат овермапа в пиксели канваса тактической схемы.
  const project = (ox, oy) => {
    const mx = Math.max(P, Math.min(W - P, sx + (ox - data.shipX) * scaleX));
    const my = Math.max(P, Math.min(H - P, sy - (oy - data.shipY) * scaleY));
    return [mx, my];
  };

  // Условный маркер окружения: форма/цвет по типу объекта овермапа.
  const markerVisual = (type) => {
    switch (type) {
      case 'star':
        return { color: '#ffdd55', shape: 'circle', size: 13 };
      case 'outpost':
        return { color: '#6ce26c', shape: 'square', size: 11 };
      case 'jump':
        return { color: '#c86cff', shape: 'diamond', size: 11 };
      case 'ship':
        return { color: '#9aa0c9', shape: 'square', size: 12 };
      case 'npc_ship':
        return { color: '#5f6473', shape: 'square', size: 11 };
      case 'event':
        return { color: '#ff5c5c', shape: 'ring', size: 11 };
      case 'static':
      case 'dynamic':
        return { color: '#5cd8ff', shape: 'circle', size: 9 };
      default:
        return { color: '#aaaaaa', shape: 'circle', size: 8 };
    }
  };

  const hasTarget = !!target && target.lockStatus !== 'lost';
  const acquiring = hasTarget && target.lockStatus === 'acquiring';

  return (
    <Section title="Тактическая схема">
      <Box
        position="relative"
        height={`${H}px`}
        backgroundColor="rgba(6, 18, 40, 0.95)"
        style={{
          border: '1px solid #223355',
          borderRadius: '4px',
          overflow: 'hidden',
        }}
      >
        {/* Радиальный радар: концентрические кольца дальности */}
        {RING_FRACTIONS.map((frac) => {
          const r = radarR * frac;
          const isOutermost = frac === 1;
          return (
            <Box
              key={`ring-${frac}`}
              position="absolute"
              style={{
                left: `${sx - r}px`,
                top: `${sy - r}px`,
                width: `${r * 2}px`,
                height: `${r * 2}px`,
                borderRadius: '50%',
                border: isOutermost
                  ? '1px solid rgba(255,255,255,0.22)'
                  : '1px dashed rgba(255,255,255,0.12)',
              }}
            />
          );
        })}

        {/* Крест прицела: вертикальный и горизонтальный лучи */}
        <Box
          position="absolute"
          style={{
            left: `${sx - 1}px`,
            top: 0,
            width: '2px',
            height: `${H}px`,
            backgroundColor: 'rgba(255,255,255,0.06)',
          }}
        />
        <Box
          position="absolute"
          style={{
            left: 0,
            top: `${sy - 1}px`,
            width: `${W}px`,
            height: '2px',
            backgroundColor: 'rgba(255,255,255,0.06)',
          }}
        />

        {/* Окружение: объекты овермапа в радиусе тактической схемы */}
        {mapObjects.map((obj) => {
          const [mx, my] = project(obj.x, obj.y);
          const vis = markerVisual(obj.type);
          const common = {
            left: `${mx - vis.size / 2}px`,
            top: `${my - vis.size / 2}px`,
            width: `${vis.size}px`,
            height: `${vis.size}px`,
          };
          let shape;
          if (vis.shape === 'circle') {
            shape = {
              borderRadius: '50%',
              backgroundColor: vis.color,
              border: `1px solid ${vis.color}`,
              boxShadow: `0 0 4px ${vis.color}`,
            };
          } else if (vis.shape === 'square') {
            shape = {
              backgroundColor: vis.color,
              border: `1px solid ${vis.color}`,
              boxShadow: `0 0 4px ${vis.color}`,
            };
          } else if (vis.shape === 'diamond') {
            shape = {
              backgroundColor: vis.color,
              border: `1px solid ${vis.color}`,
              transform: 'rotate(45deg)',
              boxShadow: `0 0 4px ${vis.color}`,
            };
          } else if (vis.shape === 'ring') {
            shape = {
              borderRadius: '50%',
              border: `2px solid ${vis.color}`,
            };
          } else {
            // triangle
            shape = {
              width: '0px',
              height: '0px',
              borderLeft: `${vis.size / 2}px solid transparent`,
              borderRight: `${vis.size / 2}px solid transparent`,
              borderBottom: `${vis.size}px solid ${vis.color}`,
            };
          }
          return (
            <Box
              key={obj.ref}
              position="absolute"
              tooltip={obj.name}
              style={{ ...common, ...shape, opacity: 0.92 }}
            />
          );
        })}

        {/* Наш корабль */}
        <Box
          position="absolute"
          style={{
            left: `${sx - DOT / 2}px`,
            top: `${sy - DOT / 2}px`,
            width: `${DOT}px`,
            height: `${DOT}px`,
            borderRadius: '50%',
            border: '2px solid #5cb8ff',
            backgroundColor: 'rgba(40, 90, 150, 0.6)',
          }}
        />
        <Box
          position="absolute"
          color="#5cb8ff"
          fontSize="12px"
          style={{ left: `${sx - 45}px`, top: `${sy + DOT / 2 + 4}px`, width: '90px', textAlign: 'center' }}
        >
          {data.shipName}
        </Box>

        {!hasTarget && (
          <Box
            position="absolute"
            color="label"
            fontSize="11px"
            style={{ left: 0, top: H - 22, width: '100%', textAlign: 'center' }}
          >
            Цель не выбрана — выберите цель для захвата
          </Box>
        )}

        {/* Линия до цели */}
        {hasTarget && (
          <>
            <Box
              position="absolute"
              style={{
                left: `${sx}px`,
                top: `${sy}px`,
                width: '2px',
                height: `${lineLen}px`,
                transform: `rotate(${lineAngle}rad)`,
                transformOrigin: 'top left',
                backgroundColor: 'rgba(120, 170, 255, 0.30)',
              }}
            />

            {/* Цель */}
            <Box
              position="absolute"
              style={{
                left: `${tx - DOT / 2}px`,
                top: `${ty - DOT / 2}px`,
                width: `${DOT}px`,
                height: `${DOT}px`,
                borderRadius: '50%',
                border: `2px solid ${acquiring ? '#ffce5c' : '#ff5c5c'}`,
                backgroundColor: acquiring ? 'rgba(150, 110, 40, 0.6)' : 'rgba(150, 40, 40, 0.6)',
              }}
            />
            <Box
              position="absolute"
              fontSize="12px"
              color={acquiring ? '#ffce5c' : '#ff5c5c'}
              style={{ left: `${tx - 105}px`, top: `${ty - DOT / 2 - 22}px`, width: '210px', textAlign: 'center' }}
            >
              {target.name}
              {acquiring && ` (захват ${Math.round(target.lockProgress)}%)`}
            </Box>

            {/* Расстояние по центру сегмента */}
            <Box
              position="absolute"
              fontSize="10px"
              color="rgba(200,220,255,0.6)"
              style={{
                left: `${sx + (tx - sx) / 2 - 34}px`,
                top: `${sy + (ty - sy) / 2 - 7}px`,
                width: '68px',
                textAlign: 'center',
              }}
            >
              {target.distance.toFixed(1)} тайлов
            </Box>

            {/* Летящие снаряды */}
            {projectiles.map((projectile) => {
              // p > 1: снаряд при промахе пролетает мимо цели и исчезает чуть позже
              const p = Math.max(0, Math.min(1.4, projectile.flightProgress / 100));
              const mx = sx + (tx - sx) * p;
              const my = sy + (ty - sy) * p;
              return (
                <Box
                  key={projectile.ref}
                  position="absolute"
                  style={{
                    left: `${mx - 5}px`,
                    top: `${my - 5}px`,
                    width: '10px',
                    height: '10px',
                    transform: 'rotate(45deg)',
                    border: '1px solid #ffb04c',
                    backgroundColor: 'rgba(255, 140, 40, 0.85)',
                    boxShadow: '0 0 6px rgba(255,140,40,0.9)',
                  }}
                />
              );
            })}
          </>
        )}
      </Box>
    </Section>
  );
};

const WeaponsSection = (props, context) => {
  const { act, data } = useBackend<FireControlData>(context);

  const renderWeapon = (weapon: WeaponData) => {
    const canFire = weapon.canFire && data.target?.lockStatus === 'locked';
    const isDamaged = !!weapon.damaged;

    // Определяем цвет состояния
    const getStateColor = () => {
      if (isDamaged) return 'bad';
      if (weapon.state === 'charging') return 'average';
      if (weapon.state === 'firing') return 'bad';
      return 'good';
    };

    return (
      <Section
        key={weapon.ref}
        title={
          <Box>
            {weapon.name}
            <Icon
              name={isDamaged ? 'exclamation-triangle' : 'check-circle'}
              color={getStateColor()}
              ml={1}
            />
          </Box>
        }
        buttons={
          <Stack>
            {isDamaged && (
              <Stack.Item>
                <Button
                  icon="wrench"
                  color="average"
                  onClick={() => act('repair_weapon', { weapon: weapon.ref })}
                  tooltip="Отремонтировать оружие"
                >
                  Ремонт
                </Button>
              </Stack.Item>
            )}
            <Stack.Item>
              <Button
                icon="fire"
                color={canFire ? 'good' : 'bad'}
                disabled={!canFire}
                onClick={() => act('fire_weapon', { weapon: weapon.ref })}
                tooltip={canFire ? 'Открыть огонь' : 'Невозможно стрелять'}
              >
                Огонь
              </Button>
            </Stack.Item>
          </Stack>
        }
      >
        <LabeledList>
          <LabeledList.Item label="Тип">
            {WeaponType[weapon.type] || weapon.type}
          </LabeledList.Item>
          <LabeledList.Item label="Состояние">
            <Box color={getStateColor()}>
              {WeaponState[weapon.state] || weapon.state}
            </Box>
          </LabeledList.Item>
          <LabeledList.Item label="Урон">
            {weapon.damage}
          </LabeledList.Item>
          <LabeledList.Item label="Точность">
            {weapon.accuracy}%
          </LabeledList.Item>
          <LabeledList.Item label="Заряд">
            <ProgressBar value={weapon.charge} maxValue={weapon.maxCharge}>
              {weapon.charge}/{weapon.maxCharge}
            </ProgressBar>
          </LabeledList.Item>
          <LabeledList.Item label="Перезарядка">
            <ProgressBar
              value={weapon.rechargeTime}
              maxValue={weapon.maxRechargeTime}
              color={weapon.rechargeTime > 0 ? 'average' : 'good'}
            >
              {Math.round(weapon.rechargeTime / 10)}с
            </ProgressBar>
          </LabeledList.Item>
          {!!weapon.damaged && (
            <LabeledList.Item label="Шанс осечки">
              <Box color="bad">{weapon.misfireChance}%</Box>
            </LabeledList.Item>
          )}
          {!!data.target && (
            <>
              <LabeledList.Item label="Расстояние до цели">
                {weapon.targetDistance.toFixed(1)} тайлов
              </LabeledList.Item>
              <LabeledList.Item label="В радиусе">
                <Box color={weapon.inRange ? 'good' : 'bad'}>
                  {weapon.inRange ? 'Да' : 'Нет'}
                </Box>
              </LabeledList.Item>
            </>
          )}
          <LabeledList.Item label="Оптимальная дальность">
            {weapon.optimalRange} тайлов
          </LabeledList.Item>
          <LabeledList.Item label="Максимальная дальность">
            {weapon.maxRange} тайлов
          </LabeledList.Item>
        </LabeledList>
      </Section>
    );
  };

  // Оптимизация: рендерим только видимые элементы
  const visibleWeapons = data.weapons?.slice(0, 10) || [];

  return (
    <Section
      title="Вооружение"
      scrollable
      fill
      buttons={
        <Button
          icon="sync"
          onClick={() => act('refresh_weapons')}
          tooltip="Обновить список вооружения на корабле"
        >
          Обновить
        </Button>
      }
    >
      {(data.activeProjectiles?.length > 0) && (
        <Section
          title="Время полёта снарядов"
          level={2}
          mb={1}
          buttons={
            <Box color="label" fontSize="10px">
              {data.activeProjectiles.length} в полёте
            </Box>
          }
        >
          <Table>
            <Table.Row header>
              <Table.Cell>Оружие</Table.Cell>
              <Table.Cell>Цель</Table.Cell>
              <Table.Cell>До попадания</Table.Cell>
              <Table.Cell>Шанс</Table.Cell>
            </Table.Row>
            {data.activeProjectiles.map((projectile) => (
              <Table.Row key={projectile.ref}>
                <Table.Cell>{projectile.weapon}</Table.Cell>
                <Table.Cell>{projectile.target}</Table.Cell>
                <Table.Cell>
                  <Box color="average" fontFamily="monospace">
                    {Math.round(projectile.timeRemaining / 10)}с
                  </Box>
                </Table.Cell>
                <Table.Cell>{projectile.hitChance}%</Table.Cell>
              </Table.Row>
            ))}
          </Table>
        </Section>
      )}

      {!data.weapons || data.weapons.length === 0 ? (
        <Box color="average" textAlign="center">
          Вооружение не обнаружено
        </Box>
      ) : (
        <>
          {visibleWeapons.map(renderWeapon)}
          {data.weapons.length > 10 && (
            <Box color="average" textAlign="center" mt={1}>
              Показано 10 из {data.weapons.length} единиц вооружения
            </Box>
          )}
        </>
      )}
    </Section>
  );
};

const CombatStatsSection = (props, context) => {
  const { act, data } = useBackend<FireControlData>(context);

  return (
    <Section title="Боевая статистика">
      <LabeledList>
        <LabeledList.Item label="Множитель урона">
          {data.combatStats.damageMultiplier.toFixed(2)}x
        </LabeledList.Item>
        <LabeledList.Item label="Множитель точности">
          {data.combatStats.accuracyMultiplier.toFixed(2)}x
        </LabeledList.Item>
        <LabeledList.Item label="Множитель перезарядки">
          {data.combatStats.rechargeMultiplier.toFixed(2)}x
        </LabeledList.Item>
      </LabeledList>
    </Section>
  );
};
