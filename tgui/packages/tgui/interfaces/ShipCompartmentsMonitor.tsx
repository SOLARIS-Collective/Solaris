import { useBackend } from '../backend';
import { Box, Button, LabeledList, ProgressBar, Section, Table, Tooltip } from '../components';
import { Window } from '../layouts';

interface CompartmentData {
  id: number;
  name: string;
  health: number;
  fireRisk: number;
  breachRisk: number;
  damaged: boolean;
  destroyed: boolean;
  status: string;
}

interface CompartmentsMonitorData {
  active: boolean;
  shipName: string;
  shipType: string;
  shipSize: number;
  compartments: CompartmentData[];
  totalCompartments: number;
  overallHealth: number;
  damagedCount: number;
  destroyedCount: number;
  highFireRisk: number;
  highBreachRisk: number;
}

const CompartmentStatus = {
  good: 'Хорошо',
  warning: 'Внимание',
  critical: 'Критично',
  damaged: 'Повреждён',
  destroyed: 'Уничтожен',
};

const healthColor = (health: number): string => {
  if (health > 70) return 'good';
  if (health > 30) return 'average';
  return 'bad';
};

const riskColor = (risk: number): string => {
  if (risk >= 30) return 'bad';
  if (risk >= 10) return 'average';
  return 'good';
};

export const ShipCompartmentsMonitor = (props, context) => {
  const { act, data } = useBackend<CompartmentsMonitorData>(context);
  const {
    active = false,
    shipName,
    shipType,
    shipSize = 0,
    compartments = [],
    totalCompartments = 0,
    overallHealth = 0,
    damagedCount = 0,
    destroyedCount = 0,
    highFireRisk = 0,
    highBreachRisk = 0,
  } = data;

  return (
    <Window width={620} height={520} resizable>
      <Window.Content scrollable>
        {!active && (
          <Section title="Нет связи с кораблём" buttons={
            <Button icon="sync" content="Обновить" onClick={() => act('refresh')} />
          }>
            <Box color="label">
              Консоль не подключена ни к одному кораблю. Проверьте питание и попробуйте обновить.
            </Box>
          </Section>
        )}
        {active && (
          <>
            <Section title={shipName || 'Корабль'} buttons={
              <Button icon="sync" content="Обновить" onClick={() => act('refresh')} />
            }>
              <LabeledList>
                <LabeledList.Item label="Тип">
                  {shipType || 'Неизвестно'}
                </LabeledList.Item>
                <LabeledList.Item label="Корпус">
                  {shipSize}
                </LabeledList.Item>
                <LabeledList.Item label="Общая целостность">
                  <ProgressBar value={overallHealth / 100} ranges={{
                    good: [0.7, 1],
                    average: [0.3, 0.7],
                    bad: [0, 0.3],
                  }}>
                    {overallHealth}%
                  </ProgressBar>
                </LabeledList.Item>
                <LabeledList.Item label="Повреждено отсеков">
                  {damagedCount} из {totalCompartments}
                </LabeledList.Item>
                <LabeledList.Item label="Уничтожено отсеков">
                  <Box color={destroyedCount > 0 ? 'red' : 'label'}>
                    {destroyedCount}
                  </Box>
                </LabeledList.Item>
                <LabeledList.Item label="Высокий риск пожара">
                  {highFireRisk > 0 ? (
                    <Box color="orange">{highFireRisk}</Box>
                  ) : (
                    <Box color="label">0</Box>
                  )}
                </LabeledList.Item>
                <LabeledList.Item label="Высокий риск разгерметизации">
                  {highBreachRisk > 0 ? (
                    <Box color="orange">{highBreachRisk}</Box>
                  ) : (
                    <Box color="label">0</Box>
                  )}
                </LabeledList.Item>
              </LabeledList>
            </Section>
            <Section title={`Отсеки (${totalCompartments})`}>
              <Table>
                <Table.Row header>
                  <Table.Cell>#</Table.Cell>
                  <Table.Cell>Отсек</Table.Cell>
                  <Table.Cell>Целостность</Table.Cell>
                  <Table.Cell>Пожар</Table.Cell>
                  <Table.Cell>Разгерм.</Table.Cell>
                  <Table.Cell>Статус</Table.Cell>
                </Table.Row>
                {compartments.length === 0 && (
                  <Table.Row>
                    <Table.Cell colspan={6} textAlign="center" color="label">
                      Отсеки ещё не просканированы
                    </Table.Cell>
                  </Table.Row>
                )}
                {compartments.map((compartment) => (
                  <Table.Row key={compartment.id}>
                    <Table.Cell>{compartment.id}</Table.Cell>
                    <Table.Cell>{compartment.name}</Table.Cell>
                    <Table.Cell>
                      <ProgressBar value={compartment.health / 100} color={healthColor(compartment.health)} width="100px">
                        {compartment.health}%
                      </ProgressBar>
                    </Table.Cell>
                    <Table.Cell>
                      <Tooltip content={`Риск возгорания: ${compartment.fireRisk}%`}>
                        <Box color={compartment.fireRisk >= 30 ? 'red' : compartment.fireRisk >= 10 ? 'orange' : 'label'}>
                          {compartment.fireRisk}%
                        </Box>
                      </Tooltip>
                    </Table.Cell>
                    <Table.Cell>
                      <Tooltip content={`Риск разгерметизации: ${compartment.breachRisk}%`}>
                        <Box color={compartment.breachRisk >= 15 ? 'red' : compartment.breachRisk >= 5 ? 'orange' : 'label'}>
                          {compartment.breachRisk}%
                        </Box>
                      </Tooltip>
                    </Table.Cell>
                    <Table.Cell>
                      <Box color={
                        compartment.destroyed ? 'red' :
                        compartment.damaged ? 'orange' :
                        compartment.status === 'critical' ? 'red' :
                        compartment.status === 'warning' ? 'orange' : 'label'
                      }>
                        {CompartmentStatus[compartment.status] || compartment.status}
                      </Box>
                    </Table.Cell>
                  </Table.Row>
                ))}
              </Table>
            </Section>
          </>
        )}
      </Window.Content>
    </Window>
  );
};