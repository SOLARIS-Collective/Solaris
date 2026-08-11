import { useBackend } from '../backend';
import { Box, Button, LabeledList, NoticeBox, Section } from '../components';
import { Window } from '../layouts';

export const Transponder = (props, context) => {
  const { act, data } = useBackend(context);
  return (
    <Window width={360} height={240}>
      <Window.Content>
        <Section
          title="Jamming Field"
          buttons={
            <>
              <Button
                icon={data.enabled ? 'power-off' : 'times'}
                content={data.enabled ? 'Enabled' : 'Disabled'}
                selected={data.enabled}
                disabled={!data.powered}
                onClick={() => act('toggle')}
              />
              <Button
                icon="sync"
                content="Reconnect"
                disabled={!data.powered}
                onClick={() => act('reconnect')}
              />
            </>
          }
        >
          {!data.powered && (
            <NoticeBox danger>
              No power! The jamming field cannot be projected.
            </NoticeBox>
          )}
          <LabeledList>
            <LabeledList.Item label="Status">
              <Box
                color={
                  data.active
                    ? 'good'
                    : data.enabled && !data.powered
                      ? 'bad'
                      : 'average'
                }
              >
                {data.active
                  ? 'ACTIVE - ship hidden from other sensors'
                  : data.enabled && !data.powered
                    ? 'NO POWER - field offline'
                    : 'INACTIVE - ship visible to other sensors'}
              </Box>
            </LabeledList.Item>
            <LabeledList.Item label="Power Draw">
              {data.power_usage + ' W'}
            </LabeledList.Item>
          </LabeledList>
        </Section>
      </Window.Content>
    </Window>
  );
};