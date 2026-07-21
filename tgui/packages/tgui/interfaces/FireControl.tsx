import { useBackend, useLocalState } from '../backend';
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
}

interface AvailableTarget {
  ref: string;
  name: string;
  distance: number;
  type: string;
  speed: number;
  heading: string;
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
  target: TargetData | null;
  availableTargets: AvailableTarget[];
  weapons: WeaponData[];
  activeProjectiles: ProjectileData[];
  combatStats: CombatStats;
  connectionStatus?: string;
  syncStatus?: string;
  lastUpdateTime?: number;
  eventCount?: number;
}

const WeaponState = {
  ready: 'Готово',
  charging: 'Зарядка',
  firing: 'Огонь',
  damaged: 'Повреждено',
  disabled: 'Отключено',
};

const TargetLockStatus = {
  none: 'Нет цели',
  acquiring: 'Захват...',
  locked: 'Захвачено',
  lost: 'Потеряно',
};

const ConnectionStatus = {
  connected: 'Подключено',
  fallback: 'Ограниченный режим',
  disconnected: 'Отключено',
  error: 'Ошибка соединения',
};

const SyncStatus = {
  synced: 'Синхронизировано',
  syncing: 'Синхронизация...',
  error: 'Ошибка синхронизации',
  delayed: 'Задержка',
};

const WeaponType = {
  laser: 'Лазер',
  kinetic: 'Кинетическое',
  missile: 'Ракета',
  energy: 'Энергетическое',
};

export const FireControl = (props, context) => {
  const { act, data } = useBackend<FireControlData>(context);
  const [lastUpdate, setLastUpdate] = useLocalState(context, 'firecontrol-lastupdate', Date.now());
  const [connectionQuality, setConnectionQuality] = useLocalState(context, 'firecontrol-quality', 'good' as 'good' | 'average' | 'bad');

  // Отслеживаем обновления данных
  if (data.lastUpdateTime) {
    setLastUpdate(data.lastUpdateTime);

    // Оцениваем качество соединения на основе времени последнего обновления
    const now = Date.now();
    const updateDelay = now - data.lastUpdateTime;

    if (updateDelay < 1000) {
      setConnectionQuality('good');
    } else if (updateDelay < 3000) {
      setConnectionQuality('average');
    } else {
      setConnectionQuality('bad');
    }
  }

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
    <Window width={1000} height={800}>
      <Window.Content scrollable>
        <Stack vertical fill>
          <Stack.Item>
            <ConnectionStatusSection
              connectionStatus={data.connectionStatus}
              syncStatus={data.syncStatus}
              connectionQuality={connectionQuality}
              lastUpdate={lastUpdate}
              eventCount={data.eventCount}
            />
          </Stack.Item>
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
              <Stack.Item grow={1}>
                <WeaponsSection />
              </Stack.Item>
              <Stack.Item grow={1}>
                <ProjectilesSection />
              </Stack.Item>
            </Stack>
          </Stack.Item>
          <Stack.Item>
            <CombatStatsSection />
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};

const ShipStatusSection = (props, context) => {
  const { act, data } = useBackend<FireControlData>(context);

  return (
    <Section title="Статус корабля">
      <LabeledList>
        <LabeledList.Item label="Корабль">
          {data.shipName}
        </LabeledList.Item>
        <LabeledList.Item label="Скорость">
          {data.shipSpeed} узлов
        </LabeledList.Item>
        <LabeledList.Item label="Курс">
          {data.shipHeading}
        </LabeledList.Item>
        <LabeledList.Item label="Сканирование">
          <Button
            fluid
            icon={data.scanning ? 'pause' : 'play'}
            color={data.scanning ? 'good' : 'default'}
            onClick={() => act('toggle_scan')}
          >
            {data.scanning ? 'Остановить' : 'Запустить'} сканирование
          </Button>
        </LabeledList.Item>
      </LabeledList>
    </Section>
  );
};

const ConnectionStatusSection = (props) => {
  const { connectionStatus, syncStatus, connectionQuality, lastUpdate, eventCount } = props;

  const getConnectionColor = () => {
    switch (connectionQuality) {
      case 'good': return 'good';
      case 'average': return 'average';
      case 'bad': return 'bad';
      default: return 'default';
    }
  };

  const getConnectionIcon = () => {
    switch (connectionQuality) {
      case 'good': return 'wifi';
      case 'average': return 'signal';
      case 'bad': return 'exclamation-triangle';
      default: return 'question';
    }
  };

  const formatLastUpdate = () => {
    if (!lastUpdate) return 'Нет данных';
    const now = Date.now();
    const diff = now - lastUpdate;
    if (diff < 1000) return 'Только что';
    if (diff < 60000) return `${Math.floor(diff / 1000)} сек назад`;
    return `${Math.floor(diff / 60000)} мин назад`;
  };

  return (
    <Section
      title="Статус соединения"
      buttons={
        <Box>
          <Icon name={getConnectionIcon()} color={getConnectionColor()} mr={1} />
          <Box style={{ color: getConnectionColor() === 'good' ? '#00FF00' : getConnectionColor() === 'average' ? '#FFFF00' : '#FF0000' }}>
            {ConnectionStatus[connectionStatus] || connectionStatus}
          </Box>
        </Box>
      }
    >
      <LabeledList>
        <LabeledList.Item label="Синхронизация">
          {SyncStatus[syncStatus] || syncStatus}
        </LabeledList.Item>
        <LabeledList.Item label="Последнее обновление">
          {formatLastUpdate()}
        </LabeledList.Item>
        <LabeledList.Item label="События">
          {eventCount || 0}
        </LabeledList.Item>
      </LabeledList>
    </Section>
  );
};

const TargetSection = (props, context) => {
  const { act, data } = useBackend<FireControlData>(context);

  const renderTargetInfo = () => {
    if (!data.target) {
      return (
        <Box color="average" textAlign="center">
          Цель не выбрана
        </Box>
      );
    }

    // Определяем цвет статуса захвата
    const getLockStatusColor = () => {
      if (!data.target) return 'default';
      switch (data.target.lockStatus) {
        case 'locked': return 'good';
        case 'acquiring': return 'average';
        case 'lost': return 'bad';
        default: return 'default';
      }
    };

    return (
      <>
        <LabeledList>
          <LabeledList.Item label="Цель">
            {data.target.name}
          </LabeledList.Item>
          <LabeledList.Item label="Статус захвата">
            <Box color={getLockStatusColor()}>
              {TargetLockStatus[data.target.lockStatus] || data.target.lockStatus}
            </Box>
            {data.target.lockStatus === 'acquiring' && (
              <ProgressBar value={data.target.lockProgress} maxValue={100}>
                {Math.round(data.target.lockProgress)}%
              </ProgressBar>
            )}
          </LabeledList.Item>
          <LabeledList.Item label="Расстояние">
            {data.target.distance.toFixed(1)} тайлов
          </LabeledList.Item>
          <LabeledList.Item label="Скорость цели">
            {data.target.speed} узлов
          </LabeledList.Item>
          <LabeledList.Item label="Курс цели">
            {data.target.heading}
          </LabeledList.Item>
        </LabeledList>
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

  return (
    <Section
      title="Управление целью"
      buttons={
        <Stack>
          <Stack.Item>
            <Button
              icon="mouse-pointer"
              onClick={() => act('select_target_manual')}
              tooltip="Выбрать цель из списка вручную"
            >
              Выбрать вручную
            </Button>
          </Stack.Item>
          <Stack.Item>
            <Button
              icon="sync"
              onClick={() => act('update_targets')}
              tooltip="Обновить список целей"
            >
              Обновить
            </Button>
          </Stack.Item>
        </Stack>
      }
    >
      <Stack fill>
        <Stack.Item grow={1}>
          {renderTargetInfo()}
        </Stack.Item>
        <Stack.Item grow={1}>
          <Section title="Доступные цели" scrollable fill>
            <Table>
              <Table.Row header>
                <Table.Cell>Название</Table.Cell>
                <Table.Cell>Расстояние</Table.Cell>
                <Table.Cell>Тип</Table.Cell>
                <Table.Cell>Действие</Table.Cell>
              </Table.Row>
              {visibleTargets.length === 0 ? (
                <Table.Row>
                  <Table.Cell colSpan={4} textAlign="center">
                    <Box color="average">Цели не обнаружены</Box>
                  </Table.Cell>
                </Table.Row>
              ) : (
                visibleTargets.map((target) => (
                  <Table.Row key={target.ref}>
                    <Table.Cell>{target.name}</Table.Cell>
                    <Table.Cell>{target.distance.toFixed(1)}</Table.Cell>
                    <Table.Cell>{target.type}</Table.Cell>
                    <Table.Cell>
                      <Button
                        icon="crosshairs"
                        onClick={() => act('select_target', { target: target.ref })}
                        disabled={!!data.target}
                      >
                        Выбрать
                      </Button>
                    </Table.Cell>
                  </Table.Row>
                ))
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

const ProjectilesSection = (props, context) => {
  const { act, data } = useBackend<FireControlData>(context);

  const renderProjectile = (projectile: ProjectileData) => {
    return (
      <Table.Row key={projectile.ref}>
        <Table.Cell>{projectile.weapon}</Table.Cell>
        <Table.Cell>{projectile.target}</Table.Cell>
        <Table.Cell>
          <ProgressBar value={projectile.flightProgress} maxValue={100}>
            {Math.round(projectile.flightProgress)}%
          </ProgressBar>
        </Table.Cell>
        <Table.Cell>{Math.round(projectile.timeRemaining / 10)}с</Table.Cell>
        <Table.Cell>{projectile.hitChance}%</Table.Cell>
      </Table.Row>
    );
  };

  return (
    <Section title="Активные снаряды" scrollable fill>
      {(!data.activeProjectiles || data.activeProjectiles.length === 0) ? (
        <Box color="average" textAlign="center">
          Нет активных снарядов
        </Box>
      ) : (
        <Table>
          <Table.Row header>
            <Table.Cell>Оружие</Table.Cell>
            <Table.Cell>Цель</Table.Cell>
            <Table.Cell>Прогресс</Table.Cell>
            <Table.Cell>Время до попадания</Table.Cell>
            <Table.Cell>Шанс попадания</Table.Cell>
          </Table.Row>
          {data.activeProjectiles.map((projectile) => renderProjectile(projectile))}
        </Table>
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
