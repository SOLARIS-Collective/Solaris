import { useBackend } from '../backend';
import { Box, Button, LabeledList, ProgressBar, Section, Stack, Table, Tabs } from '../components';
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

const WeaponType = {
  laser: 'Лазер',
  kinetic: 'Кинетическое',
  missile: 'Ракета',
  energy: 'Энергетическое',
};

export const FireControl = (props) => {
  const { act, data } = useBackend<FireControlData>();

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
      <Window.Content>
        <Stack fill>
          <Stack.Item grow={1}>
            <ShipStatusSection />
          </Stack.Item>
          <Stack.Item grow={2}>
            <TargetSection />
          </Stack.Item>
        </Stack>
        <Stack fill>
          <Stack.Item grow={1}>
            <WeaponsSection />
          </Stack.Item>
          <Stack.Item grow={1}>
            <ProjectilesSection />
          </Stack.Item>
        </Stack>
        <CombatStatsSection />
      </Window.Content>
    </Window>
  );
};

const ShipStatusSection = (props) => {
  const { act, data } = useBackend<FireControlData>();

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

const TargetSection = (props) => {
  const { act, data } = useBackend<FireControlData>();

  const renderTargetInfo = () => {
    if (!data.target) {
      return (
        <Box color="average" textAlign="center">
          Цель не выбрана
        </Box>
      );
    }

    return (
      <>
        <LabeledList>
          <LabeledList.Item label="Цель">
            {data.target.name}
          </LabeledList.Item>
          <LabeledList.Item label="Статус захвата">
            {TargetLockStatus[data.target.lockStatus] || data.target.lockStatus}
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

  return (
    <Section
      title="Управление целью"
      buttons={
        <Button
          icon="sync"
          onClick={() => act('update_targets')}
          tooltip="Обновить список целей"
        >
          Обновить
        </Button>
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
              {data.availableTargets.map((target) => (
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
              ))}
            </Table>
          </Section>
        </Stack.Item>
      </Stack>
    </Section>
  );
};

const WeaponsSection = (props) => {
  const { act, data } = useBackend<FireControlData>();

  const renderWeapon = (weapon: WeaponData) => {
    const canFire = weapon.canFire && data.target?.lockStatus === 'locked';
    const isDamaged = weapon.damaged;

    return (
      <Section
        key={weapon.ref}
        title={weapon.name}
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
            <Box color={weapon.state === 'damaged' ? 'bad' : 'good'}>
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
          {weapon.damaged && (
            <LabeledList.Item label="Шанс осечки">
              <Box color="bad">{weapon.misfireChance}%</Box>
            </LabeledList.Item>
          )}
          {data.target && (
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

  return (
    <Section title="Вооружение" scrollable fill>
      {data.weapons.length === 0 ? (
        <Box color="average" textAlign="center">
          Вооружение не обнаружено
        </Box>
      ) : (
        data.weapons.map(renderWeapon)
      )}
    </Section>
  );
};

const ProjectilesSection = (props) => {
  const { act, data } = useBackend<FireControlData>();

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
      {data.activeProjectiles.length === 0 ? (
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
          {data.activeProjectiles.map(renderProjectile)}
        </Table>
      )}
    </Section>
  );
};

const CombatStatsSection = (props) => {
  const { act, data } = useBackend<FireControlData>();

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
